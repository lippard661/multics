#!/usr/bin/env zsh
#==============================================================================
# abbrev.zsh -- the Multics abbrev framework for zsh
#
# Multics abbrev was a *line preprocessor*: it sat between the terminal and the
# command processor, rewrote the input line, and handed the result on.  The
# faithful Unix analogue is therefore NOT the shell's alias table (which is
# consulted during parsing, after the shell has already split the line) but the
# line editor.  This file implements abbrev as a ZLE widget bound to accept-line,
# so expansion happens on the raw input line exactly as it did on Multics.
#
# Requests (all are ordinary zsh functions, so the .x naming works as-is):
#
#   .a   name rest-of-line   add; expands ANYWHERE in the line
#   .ab  name rest-of-line   add; expands only at beginning of line, or
#                            directly after ; | || && ( (the Multics bol rule)
#   .af / .abf               same, but force -- no query on redefinition
#   .d / .dl / .delete names delete
#   .l   [names]             list: name, b-switch, definition
#   .lb  [names]             list beginning-of-line abbrevs only
#   .l^b [names]             list not-beginning-of-line abbrevs only
#   .la  strs                list abbrevs whose names start with strs
#   .ls  strs                list abbrevs whose names contain strs
#   .s   name                show one definition
#   .p   [path]              show / switch profile segment
#   .r   name                remember: abbreviate the previous command line
#   .esc CHAR                change the request-escape character (default .)
#   .?                       request summary
#
# A line beginning with the escape character is a request line and is never
# expanded -- which also gives you Multics' ".LINE" escape: a line typed as
# ". some command" is passed through verbatim.
#
# Install:  source /path/to/abbrev.zsh   from ~/.zshrc
#==============================================================================

: ${ABBREV_PROFILE:=$HOME/.abbrev_profile}
: ${ABBREV_ESCAPE:=.}
: ${ABBREV_MAX_PASSES:=20}     # loop guard; Multics also bounded re-expansion

typeset -gA _ABBREV_DEF _ABBREV_BOL

#------------------------------------------------------------------ profile ---

_abbrev_save() {
  emulate -L zsh
  local f=$ABBREV_PROFILE n
  : >| $f || { print -u2 "abbrev: cannot write $f"; return 1 }
  for n in ${(ko)_ABBREV_DEF}; do
    print -r -- "${_ABBREV_BOL[$n]}"$'\t'"$n"$'\t'"${_ABBREV_DEF[$n]}" >> $f
  done
}

_abbrev_load() {
  emulate -L zsh
  _ABBREV_DEF=() _ABBREV_BOL=()
  [[ -r $ABBREV_PROFILE ]] || return 0
  local bol name def
  while IFS=$'\t' read -r bol name def; do
    [[ -n $name ]] || continue
    _ABBREV_DEF[$name]=$def
    _ABBREV_BOL[$name]=$bol
  done < $ABBREV_PROFILE
}

#---------------------------------------------------------------- expansion ---
# The heart of it.  Pure string in, string out, so it is unit-testable.

_abbrev_expand_line() {
  emulate -L zsh
  setopt extended_glob
  local line=$1 out word sep rest
  local -i pass bol changed

  # A request line is never expanded.
  [[ $line == ${ABBREV_ESCAPE}* ]] && { print -r -- $line; return }

  # Break characters.  Multics' abbrev tokenised on a break set that included
  # ";"; MTB763 proposed adding the pipe token so that "lsc ;| dis" would work.
  # We treat ; | & ( ) as breaks, which is that fix plus the shell's own set.
  local -r BRK=';|&()'

  for (( pass = 1; pass <= ABBREV_MAX_PASSES; pass++ )); do
    out= ; rest=$line ; bol=1 ; changed=0
    while [[ -n $rest ]]; do
      case $rest in
        ([[:space:]]*)                    # whitespace run: copy, bol unchanged
          sep=${rest%%[^[:space:]]*}
          out+=$sep; rest=${rest#$sep}
          ;;
        ([$BRK]*)                         # separator run: copy, start a new command
          sep=${rest%%[^$BRK]*}
          [[ -n $sep ]] || { sep=$rest }
          out+=$sep; rest=${rest#$sep}; bol=1
          ;;
        (*)                               # a word
          word=${rest%%[[:space:]$BRK]*}
          [[ -n $word ]] || { word=$rest }
          rest=${rest#$word}
          if [[ -n ${_ABBREV_DEF[$word]} ]] &&
             { [[ ${_ABBREV_BOL[$word]} != b ]] || (( bol )) }; then
            out+=${_ABBREV_DEF[$word]}
            changed=1
          else
            out+=$word
          fi
          bol=0
          ;;
      esac
    done
    line=$out
    (( changed )) || break
  done
  print -r -- $line
}


#------------------------------------------------------------------- widget ---
# Two jobs, both done before the shell parses anything:
#   1. a request line is handed to _abbrev_request as ONE quoted argument, so
#      shell syntax in the definition ("| wc -l", quotes, &&) cannot be parsed
#      as part of the request.  This is what makes ".a" take rest-of-line
#      literally, the way the Multics processor did.
#   2. any other line is abbrev-expanded in the buffer.

typeset -gA _ABBREV_REQUESTS=(
  a 1  af 1  ab 1  abf 1  d 1  dl 1  delete 1
  l 1  lb 1  'l^b' 1  la 1  ls 1  s 1  p 1  r 1  esc 1  '?' 1
)

_abbrev_is_request() {          # first word of $1 is a known request?
  emulate -L zsh
  setopt extended_glob
  local w=${${1##[[:space:]]#}%%[[:space:]]*}
  [[ $w == ${ABBREV_ESCAPE}* ]] || return 1
  (( ${+_ABBREV_REQUESTS[${w#$ABBREV_ESCAPE}]} ))
}

abbrev-accept-line() {
  if _abbrev_is_request "$BUFFER"; then
    print -s -- $BUFFER                       # keep the typed line in history
    BUFFER="_abbrev_request ${(q)BUFFER}"
    (( CURSOR = ${#BUFFER} ))
  else
    local expanded=$(_abbrev_expand_line "$BUFFER")
    if [[ $expanded != $BUFFER ]]; then
      BUFFER=$expanded
      (( CURSOR = ${#BUFFER} ))
    fi
  fi
  zle .accept-line
}

_abbrev_histfilter() {          # don't also record the rewritten form
  [[ $1 != _abbrev_request\ * ]]
}

#----------------------------------------------------------------- requests ---

_abbrev_request() {
  emulate -L zsh
  setopt extended_glob
  local raw=$1 line req name rest
  line=${raw##[[:space:]]#}
  req=${line%%[[:space:]]*}
  # NB: ## (longest match), not # (shortest).  With "#" the pattern
  # [^[:space:]]## strips a single character, not the whole word, and you get
  # ".ab cwd cd" -> "b cwd cd".
  line=${line##[^[:space:]]##}; line=${line##[[:space:]]#}
  name=${line%%[[:space:]]*}
  rest=${line##[^[:space:]]##}; rest=${rest##[[:space:]]#}
  local -a args; args=( ${(z)line} )

  case ${req#$ABBREV_ESCAPE} in
    (a)            _abbrev_add - - "$name" "$rest" ;;
    (af)           _abbrev_add - f "$name" "$rest" ;;
    (ab)           _abbrev_add b - "$name" "$rest" ;;
    (abf)          _abbrev_add b f "$name" "$rest" ;;
    (d|dl|delete)  _abbrev_delete "${args[@]}" ;;
    (l|s)          _abbrev_list all  exact "${args[@]}" ;;
    (lb)           _abbrev_list b    exact "${args[@]}" ;;
    ('l^b')        _abbrev_list '^b' exact "${args[@]}" ;;
    (la)           _abbrev_list all  pre   "${args[@]}" ;;
    (ls)           _abbrev_list all  sub   "${args[@]}" ;;
    (p)            _abbrev_profile "${args[@]}" ;;
    (r)            _abbrev_remember "$name" ;;
    (esc)          ABBREV_ESCAPE=${name:-.}
                   print "abbrev: escape character is \"$ABBREV_ESCAPE\"" ;;
    ('?')          _abbrev_help ;;
    (*)            print -u2 "abbrev: unknown request \"$req\"" ; return 1 ;;
  esac
}

_abbrev_add() {                   # <b|-> <force> <name> <definition>
  emulate -L zsh
  local bol=$1 force=$2 name=$3 def=$4 ans
  [[ -n $name && -n $def ]] || {
    print -u2 "abbrev: usage: ${ABBREV_ESCAPE}a NAME REST-OF-LINE"; return 1 }
  if [[ -n ${_ABBREV_DEF[$name]} && $force != f ]]; then
    print -n "abbrev: \"$name\" is \"${_ABBREV_DEF[$name]}\". Redefine? "
    read -r ans
    [[ $ans == [yY]* ]] || { print "abbrev: not redefined."; return 1 }
  fi
  _ABBREV_DEF[$name]=$def
  _ABBREV_BOL[$name]=$bol
  _abbrev_save
}

_abbrev_delete() {
  local n
  (( $# )) || { print -u2 "abbrev: usage: ${ABBREV_ESCAPE}d NAMES"; return 1 }
  for n in "$@"; do
    if [[ -n ${_ABBREV_DEF[$n]} ]]; then
      unset "_ABBREV_DEF[$n]" "_ABBREV_BOL[$n]"
    else
      print "abbrev: \"$n\" is not defined."
    fi
  done
  _abbrev_save
}

_abbrev_list() {                  # <all|b|^b> <exact|pre|sub> names...
  emulate -L zsh
  local filter=$1 mode=$2; shift 2
  local n s; local -i show
  for n in ${(ko)_ABBREV_DEF}; do
    [[ $filter == b    && ${_ABBREV_BOL[$n]} != b ]] && continue
    [[ $filter == '^b' && ${_ABBREV_BOL[$n]} == b ]] && continue
    if (( $# )); then
      show=0
      for s in "$@"; do
        case $mode in
          (exact) [[ $n == $s   ]] && show=1 ;;
          (pre)   [[ $n == $s*  ]] && show=1 ;;
          (sub)   [[ $n == *$s* ]] && show=1 ;;
        esac
      done
      (( show )) || continue
    fi
    printf '%-14s %-2s %s\n' "$n" "${_ABBREV_BOL[$n]}" "${_ABBREV_DEF[$n]}"
  done
}

_abbrev_profile() {
  if (( $# )); then
    ABBREV_PROFILE=$1
    _abbrev_load
    print "abbrev: profile is now $ABBREV_PROFILE (${#_ABBREV_DEF} abbrevs)"
  else
    print "abbrev: profile is $ABBREV_PROFILE (${#_ABBREV_DEF} abbrevs)"
  fi
}

_abbrev_remember() {
  local name=$1 prev=${history[$((HISTCMD-1))]}
  [[ -n $name ]] || { print -u2 "abbrev: usage: ${ABBREV_ESCAPE}r NAME"; return 1 }
  [[ -n $prev ]] || { print "abbrev: no previous line."; return 1 }
  _abbrev_add b - "$name" "$prev"
}

_abbrev_help() {
  print -r -- "${ABBREV_ESCAPE}a ${ABBREV_ESCAPE}af NAME LINE    add (expands anywhere in the line)
${ABBREV_ESCAPE}ab ${ABBREV_ESCAPE}abf NAME LINE   add (expands at beginning of line only)
${ABBREV_ESCAPE}d ${ABBREV_ESCAPE}dl NAMES         delete
${ABBREV_ESCAPE}l ${ABBREV_ESCAPE}lb ${ABBREV_ESCAPE}l^b [NAMES]  list all / bol / not-bol
${ABBREV_ESCAPE}la ${ABBREV_ESCAPE}ls STRS         list by name prefix / substring
${ABBREV_ESCAPE}s NAME              show one definition
${ABBREV_ESCAPE}p [PATH]            show or switch profile segment
${ABBREV_ESCAPE}r NAME              abbreviate the previous command line
${ABBREV_ESCAPE}esc CHAR            change the request escape character
${ABBREV_ESCAPE}?                   this summary"
}

# Convenience wrappers, for use from .zshrc or a script where there is no line
# editor.  Quote the definition yourself here; the widget path does not need it.
.a()   { _abbrev_request "${ABBREV_ESCAPE}a ${(j: :)@}" }
.af()  { _abbrev_request "${ABBREV_ESCAPE}af ${(j: :)@}" }
.ab()  { _abbrev_request "${ABBREV_ESCAPE}ab ${(j: :)@}" }
.abf() { _abbrev_request "${ABBREV_ESCAPE}abf ${(j: :)@}" }
.d()   { _abbrev_delete "$@" }
.l()   { _abbrev_list all  exact "$@" }
.lb()  { _abbrev_list b    exact "$@" }
.la()  { _abbrev_list all  pre   "$@" }
.ls()  { _abbrev_list all  sub   "$@" }

#------------------------------------------------------------------ startup ---

_abbrev_load
if [[ -o interactive ]] && zmodload -e zsh/zle; then
  autoload -Uz add-zsh-hook
  add-zsh-hook zshaddhistory _abbrev_histfilter
  zle -N accept-line abbrev-accept-line
fi

#!/usr/bin/env bash
#==============================================================================
# abbrev.bash -- the Multics abbrev framework for bash
#
# A port of abbrev.zsh.  The profile file format is identical
# (b-switch TAB name TAB definition, one abbrev per line), so the same
# ~/.abbrev_profile can be shared by the zsh and bash versions.
#
# Multics abbrev was a *line preprocessor*: it sat between the terminal and the
# command processor, rewrote the input line, and handed the result on.  zsh does
# this with a ZLE widget on accept-line; bash cannot replace accept-line, so
# here Enter is bound to a readline macro that first runs a `bind -x` function
# (which rewrites READLINE_LINE) and then sends C-j, which is accept-line.
#
# Requests:
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
# ". some command" is passed through verbatim.  Typing C-j instead of Enter
# also accepts the line without expansion.
#
# Requires bash 4.0 or later (associative arrays, READLINE_LINE).  Does not
# need extglob or any other shopt, and leaves your shell options alone.
#
# Install:  source /path/to/abbrev.bash   from ~/.bashrc
#==============================================================================

: "${ABBREV_PROFILE:=$HOME/.abbrev_profile}"
: "${ABBREV_ESCAPE:=.}"
: "${ABBREV_MAX_PASSES:=20}"   # loop guard; Multics also bounded re-expansion

declare -gA _ABBREV_DEF _ABBREV_BOL

#----------------------------------------------------------------- helpers ---

_abbrev_keys() {                # abbrev names, one per line, sorted
  (( ${#_ABBREV_DEF[@]} )) || return 0
  printf '%s\n' "${!_ABBREV_DEF[@]}" | sort
}

_abbrev_ltrim() {               # strip leading whitespace from $1 into REPLY
  local lead=${1%%[^[:space:]]*}
  REPLY=${1#"$lead"}
}

#------------------------------------------------------------------ profile ---

_abbrev_save() {
  local f=$ABBREV_PROFILE n
  {
    while IFS= read -r n; do
      printf '%s\t%s\t%s\n' "${_ABBREV_BOL[$n]}" "$n" "${_ABBREV_DEF[$n]}"
    done < <(_abbrev_keys)
  } 2>/dev/null >| "$f" || { echo "abbrev: cannot write $f" >&2; return 1; }
}

_abbrev_load() {
  _ABBREV_DEF=() _ABBREV_BOL=()
  [[ -r $ABBREV_PROFILE ]] || return 0
  local bol name def
  while IFS=$'\t' read -r bol name def || [[ -n $name ]]; do
    [[ -n $name ]] || continue
    _ABBREV_DEF[$name]=$def
    _ABBREV_BOL[$name]=$bol
  done < "$ABBREV_PROFILE"
}

#---------------------------------------------------------------- expansion ---
# The heart of it.  String in ($1), string out (REPLY) -- no subshell, so it
# is cheap to call on every Enter, and still unit-testable.

_abbrev_expand_line() {
  local line=$1 out word sep rest
  local -i pass bol changed

  # A request line is never expanded.
  if [[ $line == "$ABBREV_ESCAPE"* ]]; then REPLY=$line; return; fi

  # Break characters.  Multics' abbrev tokenised on a break set that included
  # ";"; MTB763 proposed adding the pipe token so that "lsc ;| dis" would work.
  # We treat ; | & ( ) as breaks, which is that fix plus the shell's own set.
  local -r BRK=';|&()'

  for (( pass = 1; pass <= ABBREV_MAX_PASSES; pass++ )); do
    out= ; rest=$line ; bol=1 ; changed=0
    while [[ -n $rest ]]; do
      case $rest in
        [[:space:]]*)                     # whitespace run: copy, bol unchanged
          sep=${rest%%[^[:space:]]*}
          out+=$sep; rest=${rest#"$sep"}
          ;;
        [$BRK]*)                          # separator run: copy, start a new command
          sep=${rest%%[^$BRK]*}
          [[ -n $sep ]] || sep=$rest
          out+=$sep; rest=${rest#"$sep"}; bol=1
          ;;
        *)                                # a word
          word=${rest%%[[:space:]$BRK]*}
          [[ -n $word ]] || word=$rest
          rest=${rest#"$word"}
          if [[ -n ${_ABBREV_DEF[$word]} ]] &&
             { [[ ${_ABBREV_BOL[$word]} != b ]] || (( bol )); }; then
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
  REPLY=$line
}

#------------------------------------------------------------- line editing ---
# Two jobs, both done before bash parses anything:
#   1. a request line is handed to _abbrev_request as ONE quoted argument, so
#      shell syntax in the definition ("| wc -l", quotes, &&) cannot be parsed
#      as part of the request.  This is what makes ".a" take rest-of-line
#      literally, the way the Multics processor did.
#   2. any other line is abbrev-expanded in the buffer.

declare -gA _ABBREV_REQUESTS=(
  [a]=1 [af]=1 [ab]=1 [abf]=1 [d]=1 [dl]=1 [delete]=1
  [l]=1 [lb]=1 ['l^b']=1 [la]=1 [ls]=1 [s]=1 [p]=1 [r]=1 [esc]=1 ['?']=1
)

_abbrev_is_request() {          # first word of $1 is a known request?
  local REPLY w
  _abbrev_ltrim "$1"; w=${REPLY%%[[:space:]]*}
  [[ $w == "$ABBREV_ESCAPE"* ]] || return 1
  w=${w#"$ABBREV_ESCAPE"}
  [[ -n $w && -n ${_ABBREV_REQUESTS[$w]} ]]
}

_abbrev_rl_accept() {           # bound with bind -x; Enter runs this, then C-j
  local REPLY
  if _abbrev_is_request "$READLINE_LINE"; then
    history -s -- "$READLINE_LINE"            # keep the typed line in history
    printf -v READLINE_LINE '_abbrev_request %q' "$READLINE_LINE"
  else
    _abbrev_expand_line "$READLINE_LINE"
    READLINE_LINE=$REPLY
  fi
  READLINE_POINT=${#READLINE_LINE}
}

#----------------------------------------------------------------- requests ---

_abbrev_request() {
  local REPLY line req name rest
  local -a args
  _abbrev_ltrim "$1"; line=$REPLY
  req=${line%%[[:space:]]*}
  _abbrev_ltrim "${line#"$req"}"; line=$REPLY
  name=${line%%[[:space:]]*}
  _abbrev_ltrim "${line#"$name"}"; rest=$REPLY
  IFS=$' \t\n' read -r -a args <<< "$line"

  case ${req#"$ABBREV_ESCAPE"} in
    a)            _abbrev_add - - "$name" "$rest" ;;
    af)           _abbrev_add - f "$name" "$rest" ;;
    ab)           _abbrev_add b - "$name" "$rest" ;;
    abf)          _abbrev_add b f "$name" "$rest" ;;
    d|dl|delete)  _abbrev_delete "${args[@]}" ;;
    l|s)          _abbrev_list all  exact "${args[@]}" ;;
    lb)           _abbrev_list b    exact "${args[@]}" ;;
    'l^b')        _abbrev_list '^b' exact "${args[@]}" ;;
    la)           _abbrev_list all  pre   "${args[@]}" ;;
    ls)           _abbrev_list all  sub   "${args[@]}" ;;
    p)            _abbrev_profile "${args[@]}" ;;
    r)            _abbrev_remember "$name" ;;
    esc)          ABBREV_ESCAPE=${name:-.}
                  echo "abbrev: escape character is \"$ABBREV_ESCAPE\"" ;;
    '?')          _abbrev_help ;;
    *)            echo "abbrev: unknown request \"$req\"" >&2; return 1 ;;
  esac
}

_abbrev_add() {                   # <b|-> <force> <name> <definition>
  local bol=$1 force=$2 name=$3 def=$4 ans
  [[ -n $name && -n $def ]] || {
    echo "abbrev: usage: ${ABBREV_ESCAPE}a NAME REST-OF-LINE" >&2; return 1; }
  if [[ -n ${_ABBREV_DEF[$name]} && $force != f ]]; then
    printf 'abbrev: "%s" is "%s". Redefine? ' "$name" "${_ABBREV_DEF[$name]}"
    read -r ans
    [[ $ans == [yY]* ]] || { echo "abbrev: not redefined."; return 1; }
  fi
  _ABBREV_DEF[$name]=$def
  _ABBREV_BOL[$name]=$bol
  _abbrev_save
}

_abbrev_delete() {
  # Rebuilds the arrays instead of using unset "arr[$n]", which bash mangles
  # when a name contains ] $ or a backquote.
  local n k found
  local -A keep_def keep_bol
  (( $# )) || { echo "abbrev: usage: ${ABBREV_ESCAPE}d NAMES" >&2; return 1; }
  for n in "$@"; do
    [[ -n ${_ABBREV_DEF[$n]} ]] || echo "abbrev: \"$n\" is not defined."
  done
  while IFS= read -r k; do
    found=0
    for n in "$@"; do [[ $k == "$n" ]] && { found=1; break; }; done
    (( found )) && continue
    keep_def[$k]=${_ABBREV_DEF[$k]}
    keep_bol[$k]=${_ABBREV_BOL[$k]}
  done < <(_abbrev_keys)
  _ABBREV_DEF=() _ABBREV_BOL=()
  for k in "${!keep_def[@]}"; do
    _ABBREV_DEF[$k]=${keep_def[$k]}
    _ABBREV_BOL[$k]=${keep_bol[$k]}
  done
  _abbrev_save
}

_abbrev_list() {                  # <all|b|^b> <exact|pre|sub> names...
  local filter=$1 mode=$2; shift 2
  local n s
  local -i show
  while IFS= read -r n; do
    [[ $filter == b    && ${_ABBREV_BOL[$n]} != b ]] && continue
    [[ $filter == '^b' && ${_ABBREV_BOL[$n]} == b ]] && continue
    if (( $# )); then
      show=0
      # $s is unquoted on purpose: as in the zsh version, names may be globs.
      for s in "$@"; do
        case $mode in
          exact) [[ $n == $s   ]] && show=1 ;;
          pre)   [[ $n == $s*  ]] && show=1 ;;
          sub)   [[ $n == *$s* ]] && show=1 ;;
        esac
      done
      (( show )) || continue
    fi
    printf '%-14s %-2s %s\n' "$n" "${_ABBREV_BOL[$n]}" "${_ABBREV_DEF[$n]}"
  done < <(_abbrev_keys)
}

_abbrev_profile() {
  if (( $# )); then
    ABBREV_PROFILE=$1
    _abbrev_load
    echo "abbrev: profile is now $ABBREV_PROFILE (${#_ABBREV_DEF[@]} abbrevs)"
  else
    echo "abbrev: profile is $ABBREV_PROFILE (${#_ABBREV_DEF[@]} abbrevs)"
  fi
}

_abbrev_remember() {
  # The newest history entry is the ".r NAME" line itself (added by
  # _abbrev_rl_accept), so the line to remember is the one before it.
  local name=$1 REPLY prev
  [[ -n $name ]] || { echo "abbrev: usage: ${ABBREV_ESCAPE}r NAME" >&2; return 1; }
  prev=$(fc -ln -2 -2 2>/dev/null)
  _abbrev_ltrim "$prev"; prev=$REPLY
  [[ -n $prev ]] || { echo "abbrev: no previous line."; return 1; }
  _abbrev_add b - "$name" "$prev"
}

_abbrev_help() {
  local e=$ABBREV_ESCAPE
  cat <<EOF
${e}a ${e}af NAME LINE    add (expands anywhere in the line)
${e}ab ${e}abf NAME LINE   add (expands at beginning of line only)
${e}d ${e}dl NAMES         delete
${e}l ${e}lb ${e}l^b [NAMES]  list all / bol / not-bol
${e}la ${e}ls STRS         list by name prefix / substring
${e}s NAME              show one definition
${e}p [PATH]            show or switch profile segment
${e}r NAME              abbreviate the previous command line
${e}esc CHAR            change the request escape character
${e}?                   this summary
EOF
}

# Convenience wrappers, for use from .bashrc or a script where there is no line
# editor.  Quote the definition yourself here; the Enter path does not need it.
.a()   { local IFS=' '; _abbrev_request "${ABBREV_ESCAPE}a $*"; }
.af()  { local IFS=' '; _abbrev_request "${ABBREV_ESCAPE}af $*"; }
.ab()  { local IFS=' '; _abbrev_request "${ABBREV_ESCAPE}ab $*"; }
.abf() { local IFS=' '; _abbrev_request "${ABBREV_ESCAPE}abf $*"; }
.d()   { _abbrev_delete "$@"; }
.l()   { _abbrev_list all  exact "$@"; }
.lb()  { _abbrev_list b    exact "$@"; }
.la()  { _abbrev_list all  pre   "$@"; }
.ls()  { _abbrev_list all  sub   "$@"; }

#------------------------------------------------------------------ startup ---

_abbrev_load
if [[ $- == *i* ]]; then
  # Don't also record the rewritten "_abbrev_request '...'" form.
  HISTIGNORE=${HISTIGNORE:+$HISTIGNORE:}'_abbrev_request *'
  for _abbrev_km in emacs vi-insert vi-command; do
    bind -m "$_abbrev_km" -x '"\C-x\C-]": _abbrev_rl_accept'
    bind -m "$_abbrev_km" '"\C-j": accept-line'
    bind -m "$_abbrev_km" '"\C-m": "\C-x\C-]\C-j"'
  done 2>/dev/null
  unset _abbrev_km
fi

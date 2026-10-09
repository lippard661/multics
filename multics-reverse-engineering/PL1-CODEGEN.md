# Reading Multics PL/I object code: a cheat sheet

These are the patterns met while reconstructing about 45 programs compiled
by PL/I releases 27c, 28d, 28e and the 1983 "Experimental" compilers. The
current compiler (33f) generates very similar code. Code from much older
releases (such as 22a, 1977) has been reconstructed successfully too, but
expect occasional differences in semantics as well as codegen (see
WORKFLOW.md §5). Operator names are from
`pl1_operator_names_.alm` (see `tools/opnames.py`), and mxdis prints them
automatically.

## Registers and the stack frame

| Register or slot | Meaning |
|---|---|
| pr6 (sp) | this procedure's stack frame |
| pr6\|32 | argument list pointer: argument k is `epp7 pr6\|32,*` then `pr7\|2k,*` |
| pr6\|40 | display pointer, the parent block's frame (internal procedures reach the parent's variables through it: `epp7 pr6\|40,*; ... pr7\|N`) |
| pr6\|42 | descriptor-list pointer, for char(*) and other star-extent parameters (`epp7 pr6\|42,*; ldq pr7\|0,*`, then mask, gives a char(*) parameter's length) |
| pr6\|44 | linkage pointer, reloaded with `epp4 pr6\|44,*` before link references |
| pr6\|56 | scratch, often the result word of scm or tct |
| pr6\|60 and up | automatic variables and compiler temporaries |
| pr4 | linkage section: `pr4\|N,*` is link N, `pr4\|N` is internal static |
| pr0 | pl1_operators_ (`tsx0 pr0\|N`) |
| pr7 | the stack header at entry (`epp2 pr7\|34,*` gets the operators); afterwards a general pointer |
| x7, a, q | integer work; q carries most fixed bin results |

The pl1_stack_frame include file defines sp|40, 42, 44 and 46 (display,
descriptor list, linkage, text base). The variable offsets are stable
within one compilation, so build a table of `pr6|N → variable` as you go.

## Procedure structure

| PL/I | Code |
|---|---|
| `proc` / `entry` | `eax7 frame; epp2 pr7\|34,*; tsp2 pr2\|1045` (ext_entry) or 1046 (ext_entry_desc, when the parameters need descriptors: char(*), options(variable)) |
| several entries with shared code | each entry stores a different constant or sets a switch, then branches to common code |
| `return;` | `tra pr0\|631` (return_mac) |
| `return (x)` for char(*) | `return_chars_eis` (op 1235) writes the length into the caller's descriptor |
| internal procedure, quick | `tsp4 addr` to call; `rtcd pr6\|N` (saved return) to return |
| internal procedure, non-quick | `tsx0 pr0\|625` / `627` (call_int_this / call_int_other) with its own entry sequence (int_entry, 1047) |
| an external call | `epp2 pr4\|N,*` (the link), then `tsx0 pr0\|622` (call_ext_out_desc) or `623` (call_ext_out) |
| a call through an entry variable | `epp2 pr6\|N` (the variable), then `tsx0 pr0\|616` / `617` |
| a call to another component of a bound segment | `epp2 NNNN` (direct text address) then 622/623 |

An `entry variable` is assigned with `epp2 pr4|N,*; spri2 pr6|V; ldaq
<null environment>; staq pr6|V+2`. This is the usual
`get_arg = cu_$af_arg_ptr; complain = active_fnc_err_;` command/active
function setup.

## Arguments and literals

* Arguments are built with `epp2 <thing>; spri2 pr6|slot` for each argument
  and descriptor, then `eax1 pr6|base; fld N,dl` (N>>11 = argument count).
  mxdis summarises each call as `;; CALL target (arg : type, ...)`.
* A **literal integer** passed by reference becomes a temporary with a
  descriptor **fixed bin(p)**, where p is the precision needed for the
  literal's digit count (0 gives fixed bin(5), 35 gives fixed bin(8)). For
  example, `stz pr6|451` with a fixed bin(5) descriptor means the source
  said `0`, as in `call complain (0, ME, "...")`.
* A **string literal** argument is copied into a temp (`mlr` from an ic
  constant). Its descriptor is `char(n) aligned`, with n the literal's
  length.
* An expression argument always goes through a dummy, which is not a
  warning. A *variable* whose type differs from the parameter gets a dummy
  and a compile-time WARNING 47. The 33f compiler warns about this; avoid it
  by matching types, such as fixed bin for cu_$arg_ptr's index.

## Conditions and control

| PL/I | Code |
|---|---|
| `on cond ...` | `lxl6 len,dl; epp2 name_const; tsx0 pr0\|717` (enable_op); the on-unit body is a separate block |
| `revert cond` | `stz` of the on-unit's slot in the frame |
| `on cond goto L` / non-local goto | `tra_ext_1` (657) |
| `do i = a to b;` | the limit is copied to a temp; loop head `nop 0,du` / `ldq i; cmpq limit; tpnz exit`; increment with `aos i` |
| `do i = a to b by -1;` | `lcq 1,dl; asq i`, and the test is `tmi exit` against the lower bound |
| `if a = 0 \| b = 0 then` | either branches (`ldq a; tze then; ldq b; tnz else`) or comparison-to-bit operators: `r_e_as` (512), `r_ne_as` (515), `r_l_a` (474), `r_g_a` (503), `r_le_a` (520), `r_ge_a` (527), whose results are combined with `ora`/`ana` and then `tze` |
| `if ... then do; ... end;` that jumps straight to the next instruction (`tze +1`) | a test with no remaining code: a null `then`, or a `go to` a label on the loop's `end`. Comment it rather than invent code |

## Strings

| PL/I | Code |
|---|---|
| assignment of a char string | `mlr` (move left-to-right) with blank fill |
| a temp for an expression | `alloc_char_temp` (551); `cat_realloc_chars` (606) for `\|\|`; `shorten_stack` (1014) frees temps afterwards |
| `substr (s, i, n)` | a descriptor `base,ql` with q = i (offset −1 folded into the address, e.g. `pr5\|77777,ql` = word −1 + 4 chars + q) |
| `index (CONST, c)` | `scm` searching CONST for c. The common result-to-bit idiom: `ldq 1,dl; ttn +2; ldq 0,dl`, so q = 1 if *not* found. Index value form: `ttf +2; lcq 1; adq 1` |
| `verify`, `ltrim`, `rtrim` | `tct` / `tctr` with the operators' blank table; `verify_for_ltrim` / `verify_for_rtrim` operators |
| `translate (s, to, from)` | `translate_3` (1273): pr1 → from, pr2 → to, a = length(from), q = length(to); s set up first with `set_chars_eis` (1227) |
| `reverse` | a reversing operator into a temp, then mlr (seen in say_sdrawkcab_; the exact operator was inferred, not confirmed) |
| a `varying` string | the pointer is to the data, with the length word at −1 (`stz pr5\|-1` sets it to "") |
| a char(*) parameter's length | `ldq desc,*; tmi; anq 777777,dl; anq mask` |
| a char(*) `based` overlay, e.g. `char (line_length) based (addr (buf))` | the length comes from a variable at each use; the address is kept in a pointer temp |
| `unspec`, `addr`, `null` | `epp` / `spri`; null is a constant pair compared with `eraq; anaq` |

## Arithmetic

* `mpy N,dl`: N is **octal** (`mpy 64,dl` is ×52).
* Conversion of char to arithmetic: `any_to_any_truncate_` (1257). Under
  `on conversion` / `on size` this is `convert (target, arg)` or a plain
  assignment.
* Division: `divide_fx3` (1264); `mod`: `mdfx3` (706). Clock: `clock_mac`
  (1435).

## Freeing and areas

`free x` (with `x` based on a sum() extent, as star_structures uses)
computes the extent with a loop and then calls `op_freen_` (1404). Allocate
calls an alloc operator with the size in q.

## Recognising the source style

* Automatic `init` values are set by code at entry (an `mlr` from a
  constant, or `lda N,du; sta`). A string constant in the frame that is
  re-initialised on every call is `auto` with `init`, not `static`.
* `internal static options (constant)` values are text constants referenced
  ic-relative. Plain internal static is in the linkage section.
* `options (variable)` entries such as ioa_ and com_err_ are called with
  descriptors.
* Frame offsets often follow declaration order, but not reliably enough to
  prove it; treat it as a hint only.
* The `-table` symbol tree, when present, settles names, types and
  declaration order definitively.

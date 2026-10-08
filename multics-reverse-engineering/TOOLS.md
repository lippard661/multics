# Tools

The tools are in `tools/`. They need Python 3 and only the standard
library. They read the **text output** of Multics commands, so no Multics
access is needed.

| File | Purpose |
|---|---|
| `mxdis.py` | the command-line disassembler and annotator |
| `dumpload.py` | loads `dump_segment -character` output into `{address: word}`; string and character helpers |
| `mxinfo.py` | parses `print_link_info -long` and `print_bind_map -long`; decodes clock values |
| `opnames.py` | the pl1_operators_ offset → name table (generated from pl1_operator_names_.alm) |

## mxdis.py

```
python3 mxdis.py NAME.dump --plk NAME.plk                 # standalone object -> stdout
python3 mxdis.py NAME.dump --plk NAME.plk --pbm NAME.pbm --outdir dis/   # bound: one .dis per component
python3 mxdis.py NAME.dump --plk NAME.plk --range 242 410 # octal word range, end exclusive
python3 mxdis.py NAME.dump --symbols                      # strings + clock values (symbol section)
```

Sample output, from uclc_word in bound_video_ext_:

```
000410  404000000021  data   "...."   desc fixed bin(17)
...
<<< uclc_word >>>
000437  000160627000  eax7   160
000440  700034352120  epp2   pr7|34,*
000441  201045272100  tsp2   pr2|1045  ; op ext_entry (entry sequence)
000444  000100100404  mlr
000445  777760000034      desc1 777760,ic(cn0),9bit,len=28   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ\x00\x00'
000446  600104000034      desc2 pr6|104(cn0),9bit,len=28
...
000507  777702352004  epp2   -62 (=411)   [404000000025 '....' = fixed bin(21)]
000520  000255352000  epp2   255
000521  000622700100  tsx0   pr0|622  ; op call_ext_out_desc
        ;; CALL get_word_index_ (pr7|12, pr7|11 : fixed bin(21), pr7|10 : fixed bin(21), pr6|100 : fixed bin(17), pr6|101 : fixed bin(17))
000523  000512700100  tsx0   pr0|512  ; op r_e_as
000532  400010236120  ldq    pr4|10,*  ; error_table_$action_not_performed
000535  000631710100  tra    pr0|631  ; op return_mac
```

What the annotations mean:

* `data`: words before the first entry point of the range (constants).
  Descriptor words are decoded.
* `<<< name >>>`: entry points from the plk definitions.
* `; name` on a `pr4|N,*` reference is the link name; `; static/linkage+N`
  is internal static in the linkage section.
* `; op name` is a pl1_operators_ entry.
* `= '...'` is the string an ic-relative EIS descriptor points to.
* `[word 'ascii' = type]` is the constant word an ic-relative epp/lda/ldaq
  uses, decoded when it is an argument descriptor.
* `;; CALL target (args)` is reconstructed from the argument-list-building
  sequence. Argument types come from the descriptors, where the call passes
  them. A direct `epp2 NNN` to another bound component is named from the
  definitions. Descriptors built at run time show as
  `<length filled in at run time>`.

Limits:

* Instructions it doesn't know are printed as `.word`. Coverage is what
  PL/I code uses.
* Code isn't separated from inline constants that come after the first
  entry. You'll see a few nonsense "instructions" there; check the ASCII
  column.
* The call summary follows the usual compiler pattern (`spri2` into the
  argument list, `eax1`, `fld`, `tsx0 pr0|62x`). Unusual sequences may
  show `?` for an argument.

## Library use

```python
import dumpload, mxinfo
from mxdis import Disassembler, descriptor
m = dumpload.load('X.dump')
info = mxinfo.parse_plk(open('X.plk').read())
d = Disassembler(m, info['links'], {e['offset']: [e['name']] for e in info['defs'] if e['section']=='text'})
print('\n'.join(d.disassemble(0o437, 0o616)))
dumpload.string_at(m, 0o415, 0, 26)          # 'abcdefghijklmnopqrstuvwxyz'
mxinfo.clock(0o111653, 0o752111137667)       # datetime(1983, 4, 28, 22, 2, 44, ...)
descriptor(0o526077777777)                   # 'char(*)'
```

Small throwaway scripts on top of these were useful for specific jobs.
Examples from the sessions: listing every call with its arguments,
extracting the replacement-rule tables from a text translator
(say_french_), and annotating a whole component file.

## Regenerating opnames.py

The table comes from `>ldd>sss>s>bound_debug_util_.s.archive::pl1_operator_names_.alm`.
Normal operators are at offset `361 + index` (decimal), and the "special"
operators at their own decimal offsets. The transfer-vector offsets have
stayed stable across releases, with new operators appended.

## Worked example

`examples/bound_video_ext_/` contains a real input set: the dump, plk and
pbm output for a 1983 bound segment. It also has the tool's output for one
component (`uclc_word.dis`) and the faithful reconstruction made from it
(`uclc_word.reconstructed.pl1`). Use it to check the tools, or to see how a
disassembly maps to source.

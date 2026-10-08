# Multics object segments: what's in the dump

Everything here was confirmed against real dumps in this project. Addresses
and offsets are octal word numbers, as Multics prints them.

## Words and characters

* A word is 36 bits. Characters are 9 bits, four per word, numbered 0–3
  from the left. Character strings are packed this way, and so are the
  ASCII columns of `dump_segment -ch`.
* Addresses are word addresses. A pointer register with a word offset and a
  character offset addresses a single character.
* In EIS descriptors, the CN field (bits 18–20) gives the starting character
  as CN/2 for 9-bit data, so only the values 0, 2, 4 and 6 occur.

## Sections (the Start/Length table from print_link_info)

```
        Object    Text    Defs    Link    Symb  Static
Start        0       0    1120    1266    1304    1276
Length    3016    1120     146      16    1476       0
```

* **Text:** code and constants. It begins at 0 and runs up to Defs.
* **Defs:** definitions, meaning the entry names and segnames as ACC
  strings (a length byte, then the characters), threaded together.
  print_link_info decodes these for you.
* **Link:** the linkage section, a header and then two-word links. Link N is
  reached through the linkage pointer as `pr4|N,*`. In a perprocess_static
  bound segment, internal static also lives in the linkage section and is
  addressed as `pr4|N` without indirection.
* **Symb:** the symbol section. It holds the compiler's provenance block
  ("symbtree"), source map, optional `-table` symbol tree and, for a bound
  segment, the bind map.
* **Static:** separate internal static (absent or empty for perprocess
  static).

## Text-section layout of a PL/I procedure

1. **Constants** come first, before the first entry point:
   * argument descriptors for the procedure's own calls;
   * string literals (NUL-padded to a word, so read the descriptor
     length);
   * constant tables, and the procedure's own parameter-descriptor list.
2. **Two words before each entry point:**
   * entry−2 points to the parameter-descriptor list. That list is a count,
     followed by descriptor addresses packed two per word. For example,
     `000002000004 000003000000` means 2 parameters, with descriptors at
     text|4 and text|3.
   * entry−1 is an entry-information word.
3. **Entry sequence:**
   ```
   eax7   160            frame size (words) for this entry
   epp2   pr7|34,*       pl1_operators_ via the stack header
   tsp2   pr2|1045       ext_entry   (1046 = ext_entry_desc, 1047 = int_entry)
   .word  ...            two words used by the operator
   ```
   This may be followed by `tsx0 <block>` into an automatic-initialisation
   block, or by in-line `mlr`/`lda;sta` sequences that set `init`
   values for automatic variables. Constants used for `init` appear among
   the leading constants.
4. **Code** follows, with internal procedures after the main body. The
   tools print the leading constants as `data` lines and mark entry points
   from the plk definitions with `<<< name >>>`.

## Argument descriptors

A descriptor word is laid out as:
* a flag bit;
* a 6-bit type;
* a packed bit;
* 4 bits for the number of dimensions;
* a 24-bit size (precision in the low 12 bits and scale in the high 12 for
  fixed-point; length for strings, with 77777777 octal meaning `*`).

| First 3 octal digits | Type |
|---|---|
| 404 | fixed bin (size = precision, e.g. 404000000021 = fixed bin(17), …43 = fixed bin(35)) |
| 410 | fixed bin long (fixed bin(71)) |
| 464 | pointer |
| 500 | entry |
| 514 / 516 | bit, aligned / unaligned |
| 524 / 526 | char, aligned / unaligned (526077777777 = char(*)) |
| 530 | char varying (530077777777 = char(*) varying) |

A descriptor with size 0, such as `526000000000`, is a template. The code
fills in the length at run time with `ldq length; orq 526000,du; stq temp`.
This shows the argument's length is computed at run time.

## Calls, arguments and the linkage

* External calls go through links: `epp2 pr4|N,*` then
  `tsx0 pr0|622` (call with descriptors) or `623` (without).
* In a bound segment, the binder resolves calls between components to
  direct text addresses, such as `epp2 255`. Map them to entry names with
  the plk definitions; mxdis does this automatically.
* The argument list, built in the caller's frame, is laid out as:
  * a header (the argument count, loaded as `fld N,dl`, where N>>11 is the
    count);
  * the argument pointers at `base+2+2i`;
  * the descriptor pointers at `base+2+2n+2i`. For calls through an entry
    variable (operators 616/617) and for internal calls, there is a
    two-word environment pointer between the argument pointers and the
    descriptor pointers.

## The symbol section

* **The "symbtree" header** (find it with `mxdis.py --symbols`) contains:
  * two clock values, the compiler's creation time and then the
    **compilation time**;
  * the generator name (`PL/I    `);
  * the compiler version string, such as "Experimental PL/I Compiler of
    Friday, April 15, 1983 at 16:41";
  * the **user id** that compiled the program (Person.Project.tag);
  * the comment (`optimize`);
  * a `pl1info` source map listing each source path with its
    date-time-modified.

  These match print_link_info, but they are also present inside each
  component of a bound segment, where only the bind map summarises them.
* **The `-table` symbol tree.** If the program was compiled with `-table`,
  the tree includes every variable's **name**, type and stack offset (for
  example `start_pos` at pr6|100). This gives the original names. It's
  worth checking every component for one, because authors often compiled
  only some components with `-table`.
* **The bind map** (bound segments): the binder version, the archive path,
  each component with its compiler and section ranges, and the bindfile
  name and dates. print_bind_map prints all of this. The dates sometimes
  show the locale the binder ran in: "Do" in one map was German
  "Donnerstag".

## Clock values

A Multics clock value is a fixed bin(71): microseconds since 1901-01-01
00:00 GMT, stored in two words. Decode it with `mxinfo.clock(hi, lo)`. For
example, `000000111653 752111137667` is 1983-04-28 22:02:44 UTC, which is
15:02 PDT, matching "04/28/83 1502.7" in the bind map. The high word of a
1970s–2030s date is between about 070000 and 200000 octal.

## Bound segments

* Components are concatenated in the bindfile's `Order`. Each keeps its own
  constants, entry sequences and symbol block.
* Relocation information is discarded, so a component's object can't be
  extracted and rebound easily. Keep the original bound segment as an
  artifact, and rebuild from reconstructed source and a new bindfile.
* With `Perprocess_Static`, all internal static is in the linkage section
  (`pr4|N`).
* The definitions list only the names retained by the bindfile. A compiled
  entry that isn't in the definitions (such as whom's `long` entry) was
  deliberately left unretained.

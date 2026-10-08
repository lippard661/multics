# Inputs: what to ask for, and what each tells you

You can't run Multics commands yourself. The person runs them, on a live
system or an emulator such as DPS8M, and sends the output as text
attachments. Ask for all of it at once.

## Required

### 1. `dump_segment PATH -character` (short form: `ds PATH -ch`)

This gives the octal words of the whole segment, four per line, with an
ASCII rendering:

```
	>udd>m>jjl>l>e>bound_video_ext_  (347|0)  	10/04/26  1814.1 pdt Sun

000000 404000000021 404000000025 526000000000 404000000043 ...............#
000004 464000000000 000002000004 000003000000 000005000000 ................
======
001400 040040040040 040040040000 000000000000 000000000000        .........
```

* `======` means one or more lines identical to the previous line were
  left out. `dumpload.py` fills them back in.
* Ask for the entire segment, not just the text section. The constants,
  definitions, links and symbol section all matter.
* For a large segment, the person can send the output to a file with
  `file_output X.dump` ... `revert_output`, then transfer the file.

### 2. `print_link_info PATH -long` (short form: `pli PATH -lg`)

* **Created on / by / using:** the compile date, the user id
  (Person.Project.tag) and the exact compiler version, for example
  "Multics PL/I Compiler, Release 28d, of October 4, 1983". These tell you
  which codegen to expect, and they help date the program.
* **Comment:** usually `optimize` (from `-optimize`). With `-table` there is
  a full symbol table, which gives the original variable names (see
  OBJECT-FORMAT.md).
* **Source:** every source file and include file, with full pathnames and
  date-time-modified. This shows the author's directory layout, the include
  files used, and an upper bound on the writing date. Pre-release include
  directories, such as `>x>tvd>incl` for the early video system, are
  themselves evidence.
* **Start/Length table:** the word offsets of the Text, Defs, Link, Symb and
  Static sections. The text section ends where Defs starts.
* **Definitions:** each entry point with its text offset (`text|11
  deunderline_word Entrypoint`) and segname. For a bound segment, this is
  the list of names the components kept as callable entries.
* **Links:** `link|N  external_name`. The code references link N as
  `pr4|N,*`, so this table names every external call and every error_table_
  code the program uses. Read it first: it is the best single summary of
  what the program does.

### 3. For a bound segment: `print_bind_map PATH -long` (short form: `pbm PATH -lg`)

* One row per component: text start and length, internal static and symbol
  ranges, the date compiled, and the language. The tools use the text
  ranges to cut the dump into components.
* The bindfile name and dates, and the archive path the segment was bound
  from.
* Components are often compiled at very different times, years apart, by
  different user ids. Record every one: they date the components
  individually.

## Very useful when they exist

* **Any related source.** It is often a better starting point than the
  disassembly. Look for:
  * a system command the program was modified from (whom/who,
    generate_words and system all were);
  * a later installed version (get_effective_access was);
  * a colleague's copy (Eric Swenson had copies of whom and when);
  * a version recovered from a backup.

  When there's a base, reconstruct the differences rather than the whole
  program. The system source tree, `>ldd` (library_dir_dir) with its
  `*.s.archive` sources and include directory, was available locally in
  this project and was searched with grep.
* **Include files** named in the Source list, ideally the versions of the
  time. The current ones are usually close enough, but check for changed
  constants. For example, suffix_info's FS_OBJECT_TYPE_MSF changed from
  "-multi_segment_file" to "-multisegment_file" in November 1984.
* **`pl1 -list` output (`pl1 X -ls`)** of your reconstruction, compiled on
  the person's system. The listing interleaves source lines with the
  generated instructions, so you can compare it against the disassembly of
  the original, statement by statement. Expect harmless differences in
  register choice and temp-slot numbering, and larger ones between compiler
  releases (for example 27c/28d against today's 33f). Look for matching
  structure: the same calls, the same tests, the same string operations.
* **A listing of similar code** compiled by the same compiler. Use it when an
  idiom is unclear: ask the person to compile a few lines with `-list` that
  use the construct you suspect.
* **The person's memory and documents**: info segments, mail mentioning the
  program, exec_coms or abbrevs that call it. In this project, a recovered
  `start_up.ec`, an abbrev file, a persons file and old mail all settled
  questions the code couldn't. One example is the meaning of "assq".

## During and after

* Ask the person to **compile** each reconstruction and report every ERROR
  and WARNING verbatim, then **run** it and report the behaviour. Real
  failures found this way: a char(*) return protocol change; an
  interface whose time-zone argument went from char(3) to char(4);
  `no_write_permission` from a stale caller declaration.
* If two systems give different results, ask which version of each
  dependency is installed on each. In one case, an old bound copy of
  long_date_ explained everything.

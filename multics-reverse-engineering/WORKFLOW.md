# Reconstruction workflow

## 1. Triage (before disassembling anything)

* Read the **print_link_info** output for:
  * the compiler release and date, and the user id and project;
  * the source pathnames, include files and dates;
  * the **links**. The external entries a program calls usually tell you
    most of what it does. For example, `hcs_$star_`, `check_star_name_`
    and `fs_util_$get_user_access_modes` together mean "report access on a
    starname".
* Run `mxdis.py X.dump --symbols` to list every string: control arguments
  (`-ring`, `-fcnt`), messages and usage lines, ioa_ control strings, and
  dates. Usage strings such as `"Usage: ^[[^]gea paths {-control_args}^[]^]"`
  give the command's interface directly.
* For a bound segment, read the **bind map** and record each component's
  compile date, user id and source directory.
* Write down what you expect the program to do, and check it against the
  person's memory.

## 2. Look for a base source

This is often the biggest saving.

* Search the system source tree for the program's name and its distinctive
  strings. Modified system commands, such as whom from who.pl1 or
  generate_words, and programs later installed in the system, such as
  get_effective_access, can be reconstructed **as differences from the
  base**:
  1. Take the base source.
  2. Use its **history comments** to back out changes made after the
     object's compile date.
  3. Walk the disassembly statement by statement and change the source
     until it matches.
  4. List exactly what differs: added or removed control arguments,
     messages, logic.
* Ask the person whether colleagues might have copies.
* When the object turns out to be **identical apart from later
  maintenance**, say so plainly. The person may decide it isn't worth
  keeping, as happened with get_effective_access.

## 3. Disassemble and annotate

```
python3 tools/mxdis.py X.dump --plk X.plk [--pbm X.pbm --outdir dis/]
```

* Work component by component. Each component's leading `data` lines give
  its constants and its own parameter descriptors, which tell you the
  entry's parameter types.
* Build a table of `pr6|N` → variable name, type and role. Use the `;; CALL`
  lines: the argument types of known system entries tell you your
  variables' types. Look up the real declarations in the system source or
  include files.
* If any component has a `-table` symbol tree, take the names from it and
  use the same naming style elsewhere.
* For strings, read the `= '...'` annotations. A string constant inside an
  EIS descriptor is ic-relative **to the EIS instruction word**.

## 4. Write the PL/I

* Write in the **original author's style**: their declaration layout,
  naming, comment style and idioms (for example `complain`/`get_arg` entry
  variables, or `ME` constants). Copy the system include files rather than
  re-declaring structures.
* **Reproduce the behaviour exactly, bugs included**, in the first
  version. Document each bug in the header ("Notes on the original:")
  instead of silently fixing it. Fix bugs only when asked, and keep the
  unfixed version (this project kept them in `orig_*/` directories).
* Mark anything you couldn't determine as `/* UNCERTAIN: ... */`.
* When a test leaves no code behind (a dead compare), say so in a comment
  rather than inventing a statement.

## 5. Port to the current system

These changes were needed for MR12.8 with PL/I 33f. Record each one in the
header as "Change needed for current Multics: …":

| Problem | Fix |
|---|---|
| A function returning `char (*)` (e.g. long_date_ compiled with 33f) now returns through `return_chars_eis`, which writes the length into the caller's descriptor. A caller declaring `returns (char (50))` gets `fault_tag_1` or `no_write_permission` | Declare `entry (...) returns (char (*))` in callers (since PL/I 28e, 1985) |
| `decode_clock_value_$date_time` zone argument changed from char(3) to char(4) (MCR10023): "The time zone is not acceptable" | Use char(4) |
| `message_facility_$send_message` signature changed to (dname, ename, msg, info_ptr, code) (MCR7298) | Use the new signature |
| canonicalize_ used to return its own output pointer; it now copies into the caller's buffer | Point the output pointer at a local buffer first |
| include-file constants changed (suffix_info FS_OBJECT_TYPE_MSF) | Note it; normally use the current include |
| WARNING 47: an aligned structure member passed to char(*), or a mismatched variable argument | Drop `aligned` or use a matching-type index variable |
| WARNING 235: implicit string→arithmetic conversion | Use `binary (x, p)` |
| ERROR: `go to` into a do-group | Move the label outside the group |
| A variable named `then` | Rename it |
| Nested comments | Not allowed in PL/I; rewrite |

Before using any system entry, check its current declaration in the
source tree.

## 6. Verify on the real system

The person compiles each file and reports ERRORs and WARNINGs verbatim,
then runs it. Optionally they compile with `-list` so you can compare its
generated code with the original's disassembly. If results differ between
two systems, compare the installed versions of each dependency.

## 7. Bindfiles for bound segments

Derive these from the plk definitions and the bind map:

```
/* Bindfile for bound_video_ext_. ... */
Objectname:	bound_video_ext_;
Order:		deunderline_word, get_word_index_, uclc_word,
		underline_word;			/* the bind map's order */
Addname:	deunderline_word, get_word_index_, uclc_word,
		underline_word;			/* every segname in the definitions */
Global:		delete;
Perprocess_Static;				/* if the attributes say perprocess_static */

objectname:	get_word_index_;
 synonym:	...;				/* extra segnames for this component */
 retain:	get_word_index_, next_word;	/* the component's entries in the definitions */
```

Leave out entries that the original didn't retain, and say so in a comment.

## 8. Header, history and dating conventions (used in this project)

```
/* Reconstructed source code by Claude Opus 5.5 4 Oct 2026 */
/* Original source written by Jim Lippard, probably between February and
   April 1983, and last compiled on 28 April 1983. */
```

* For a modified base program: `/* Original source: <program> by Honeywell
  <authors from its history>; modified by <person> and last compiled on
  <date>. */`.
* **Dating.** The compile date is an upper bound. Narrow the start with
  evidence, and say what it is:
  * the date of an interface the code depends on (window_line_editor,
    February 1983);
  * a pre-release include directory;
  * the compiler release;
  * the user id and project the program was compiled under (the person's
    jobs and accounts changed over time);
  * source date-time-modified in the plk Source list;
  * the first mention in mail.
* **History comments.** Credit the original author, then the
  reconstruction, then each later fix, for example:
  `Modified by Claude Opus 5.5, 2026/10/05 - fixed ...`. When a modified
  system program is reconstructed, add the author's (reconstructed)
  changes as a history entry, keep the Honeywell history, and list the
  differences from the base.
* Write the person's own name only as they want it to appear, and
  attribute AI work to the model by name.

## 9. Using subagents for large jobs

For a bound segment with many components, give each component to a
subagent, with a **shared prompt file** containing:

* where the dump and tools are, and how to call them;
* the component table (text start/length, entry offsets, compile dates);
  for binder-resolved cross-calls, the text addresses of the other
  components' entries;
* the location of the system source and include files;
* the codegen conventions from PL1-CODEGEN.md;
* the exact header to use, the porting rules, and the instruction to mark
  uncertainties;
* the report format to return: what the program does, usage, calls,
  porting changes, kept bugs, uncertainties, in under 350 words.

Review each result yourself before giving it to the person.

## 10. Lessons and pitfalls

* Don't claim a program was reconstructed until it has been. One session
  wrongly said nol had been.
* Check authorship and attributions against comments, mail or the person.
  Don't guess.
* Before "fixing" a cosmetic behaviour, check whether it actually happens.
  Whether ioa_ `^a` drops trailing blanks was unverified, so the fix was
  written to be correct either way.
* Uninitialised variables, ignored error codes and reads past the end of a
  string are common in the originals. Report them, but keep them until a
  fix is requested.
* Keep the original binaries. They are the evidence.

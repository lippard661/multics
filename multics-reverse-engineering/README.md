# Reconstructing PL/I source from Multics object segments

This folder records how lost Multics PL/I programs were rebuilt from their
compiled object segments in this project (October 2026). The work covered
about 45 programs: Jim Lippard's bound_say_, bound_tools_,
bound_modified_cmds_ and bound_video_ext_, plus get_effective_access. It is
written for other Claude sessions and for Multics developers who use Claude
or Claude Code, so the method doesn't have to be rediscovered.

The approach in brief:

1. On Multics, run three commands on the object segment and capture their
   output as text: `dump_segment -character`, `print_link_info -long`, and,
   for a bound segment, `print_bind_map -long`.
2. Find any related source: a base version it was modified from, an older
   or newer copy, or the system's own version.
3. Disassemble with the Python tools here. They annotate links, operators,
   string constants, argument descriptors and call sites.
4. Read the disassembly against PL/I's code-generation idioms and write PL/I
   that compiles to the same logic, in the original author's style.
5. Have the person compile it on a real Multics, then fix errors and test.
   Keep the original behaviour, quirks included. Make porting changes and
   bug fixes separately, and record them in the header and history comments.

| File | Contents |
|---|---|
| [INPUTS.md](INPUTS.md) | What to ask the person for: the exact commands, what each output tells you, and optional extras such as `pl1 -list` |
| [OBJECT-FORMAT.md](OBJECT-FORMAT.md) | Object segment layout: sections, entry sequences, descriptors, linkage, symbol section, clock values, bound segments |
| [PL1-CODEGEN.md](PL1-CODEGEN.md) | Cheat sheet mapping instruction sequences back to PL/I: stack frame, calls, operators, strings, loops, conditions |
| [WORKFLOW.md](WORKFLOW.md) | The reconstruction procedure, porting to current Multics (PL/I 33f), header, history and dating conventions, bindfiles, using subagents |
| [TOOLS.md](TOOLS.md) | The Python tools (`mxdis.py`, `dumpload.py`, `mxinfo.py`, `opnames.py`): usage and output |
| [CASE-STUDIES.md](CASE-STUDIES.md) | Short notes on each reconstruction and what it taught |
| `tools/` | The tools themselves (Python 3, standard library only) |
| `examples/bound_video_ext_/` | A real input set (dump, plk, pbm), the tool's output for one component, and its reconstruction |

A quick start (the tools are in `tools/`):

```
python3 tools/mxdis.py prog.dump --plk prog.plk > prog.dis               # standalone object
python3 tools/mxdis.py bnd.dump --plk bnd.plk --pbm bnd.pbm --outdir dis/ # bound segment: one .dis per component
python3 tools/mxdis.py prog.dump --symbols                                # strings and dates in the symbol section
```

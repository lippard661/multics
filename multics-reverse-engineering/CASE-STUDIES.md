# Case studies (Jim Lippard's programs, reconstructed October 2026)

All the objects came from a recovered MIT-Multics backup. Reconstructions
were compiled and tested on Gold Hill and Baja Biltmore Multics (PL/I 33f).

| Object | Method | What it taught |
|---|---|---|
| **bound_say_** (say, auto_bye, and the translators say_french_, say_german_, say_japanese_, say_morse_, say_rot13_, say_sdrawkcab_) | Full reconstruction from the disassembly. The translators are table-driven, and a script pulled out their replacement rules | Components compiled years apart (1982–85) by different user ids. The bind map's "Do" date showed the binder ran with German day names. `-apply NAME` finds translators at run time with `hcs_$make_entry` |
| **bound_tools_** (26 components: iso_date, long_date_, monitor_mailbox, video_, answerer, idwblo, ...) | One subagent per large component, with a shared prompt file. Binder-resolved cross-calls were mapped to the other components' entry addresses | Porting problems found by compiling and running: char(*) returns (long_date_ / longer_date), decode_clock_value_ char(4) zone. The original assq source turned up later, and comparing it showed where the re-creation differed |
| **bound_modified_cmds_** (generate_words, system, whom) | **Base source plus differences.** The system or colleague's source, with later changes backed out using its history comments, then edited to match the object | It identified exactly what the author had changed. A bug in the modified whom ("User not logged in" never printed when daemons were counted) was found and fixed on request, with history credit |
| **bound_video_ext_** (deunderline_word, get_word_index_, uclc_word, underline_word) | Full reconstruction. uclc_word had a `-table` symbol tree, which gave the original variable names | Pre-release include path (`>x>tvd>incl`) dated the code to the video system's first months. canonicalize_'s output-pointer semantics had changed since. The first version kept the original bugs (cursor placement, a 512-character overflow, repeat counts); they were fixed later on request |
| **get_effective_access** | Compared with the installed source (which descends from the same code) | The object was the installed program minus two later maintenance changes (MCR7122, MCR7366), so there was no reason to keep a separate version |
| **idwblo** ("I don't wanna be logged out") | Full reconstruction | Small and self-contained. Later found in the last MIT-Multics forum transactions (2 Jan 1988), where people ran it to outlast the final shutdown |

## Scale

* A small command (a few hundred words of text) is usually done in one pass
  from a single disassembly.
* A large component, such as video_ (about 4,400 words of text), is best
  given to a subagent with the shared prompt, then reviewed.
* For a modified system program, the work depends on how close the base
  source is. With a good base it is mostly careful diffing.

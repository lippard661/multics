# multics

This repository, originally for files and information related to
using the DPS8M Multics simulator on OpenBSD, now also contains
Unix-like tools for Multics and Multics-like tools for Unix.

The main directory retains its original purpose. PL/I
implementations of Unix-like tools are in the UnixOnMultics
subdirectory and implementations of Multics-like tools
for Unix are in the MulticsOnUnix subdirectory.

Currently in UnixOnMultics: unix_patch.pl1, unix_diff.pl1,
encode_base64.pl1, decode_base64.pl1, sha256.pl1,
secure_hash_.pl1, and secure_hash_state.incl.pl1.

Currently in MulticsOnUnix: abbrev.zsh (Multics abbrev
for zsh; I'm currently using it on macOS)

--

The DPS8M simulator and information on installing it on various
operating systems can be found here:

https://dps8m.gitlab.io/dps8m/

I'm using r3.1.0, built from source.

Information on setting up the Multics simulator on the latest release
can be found here:

https://multics-wiki.swenson.org/

This OpenBSD setup presumes that you set up a "_multics" user and
group and put your dps8 init file in the user's home dir.  Under that
dir, create a directory "cards" containing subdirs "rdra", "rdrb", and
"rdrc" to facilitate importing files into the simulator environment
with the card deck.  Add these lines to your .ini, after the "set fnp"
lines (typically commented out to start):

```
; Card reader
set rdr nunits=1
set rdr path=/home/_multics/cards
set rdr debug
set rdr0 watch
set rdr0 card_type=mcc
```

This version of shutdown_multics.pl is now fairly reliable, but if it
fails you can connect to the console with the "multicscons" alias
defined below and do a new "shutdown" and then the BCE "die."

I'm still not making my system available to the Internet (or even to my
local network), though I am considering doing so in the future. That
requires use of dps8m-proxy, which can be found here:

https://github.com/johnsonjh/dps8m-proxy

I use Eric Swenson's Gold Hill Multics (aka GHM, the main Multics
development system these days, the equivalent of Honeywell's System
M), and the I/O performance using the proxy over SSH to GHM is much
better than telnet to localhost for my system.

# Individual user aliases
```
alias loginmultics='/usr/bin/telnet localhost 6180;/usr/bin/reset'
```

# Root aliases:
```
alias startmultics='/usr/bin/rcctl start multics'
alias stopmultics='/usr/bin/perl /usr/local/bin/shutdown_multics.pl'
alias multicscons='/usr/bin/su -s /bin/sh _multics -c "/usr/bin/tmux attach-session -t multics"'
```

# Files in the repo:

```text
multics:  rc.d/multics, for starting up Multics with "rcctl start multics"
shutdown_multics.pl:  perl script to shut down Multics
```


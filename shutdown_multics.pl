#!/usr/bin/perl
#
# /usr/local/bin/shutdown_multics.pl
#
# Prompt-driven shutdown of the DPS8M Multics simulator running in tmux.
# Instead of sleeping for fixed intervals, it logs everything the console
# prints (tmux pipe-pane). It then waits for each expected prompt before
# sending the next keystroke. Daemon chatter on the console (IO daemons, card
# reader, etc.) therefore can't push it out of sync. Each step returns as
# soon as its prompt appears.
#
# If any step times out, the script prints a console snapshot and exits 1
# WITHOUT killing the simulator, so you can finish by hand without risking
# the disk images.

use strict;
use warnings;
use Time::HiRes qw(sleep time);

$| = 1;    # unbuffered output, so progress shows live under rcctl -d

# --- CONFIGURATION ---
my $tmux_bin    = '/usr/bin/tmux';
my $pgrep_bin   = '/usr/bin/pgrep';
my $target_user = '_multics';
my $session     = 'multics';
my $pane        = "$session:0.0";
my $pexp        = '.*dps8 /home/_multics/MR12.8_boot.ini';    # same as rc script
my $console_log = '/home/_multics/.shutdown-console.log';      # kept for debugging

# Log out all daemons with 'logout * * *' before 'shut' (the clean way).
# If any are still on when 'shut' runs, its "Do you want to shut down?"
# question is answered 'y' as a fallback.
my $logout_daemons = 1;

# Per-step timeouts in seconds. The worst case, with every retry used, is
# about 445 s, which stays under daemon_timeout=450 in /etc/rc.d/multics.
# A normal run takes well under a minute.
my %T = (
    attention       => 5,     # wait for M-> after each ESC
    attention_tries => 4,     # ESC retries if daemon output delays the prompt
    settle          => 2,     # pause after a prompt before typing (the console
                              # shows the prompt before its read is ready, and
                              # keys typed in that gap are dropped)
    echo            => 6,     # wait for typed text to echo back (it can lag)
    type_tries      => 3,     # retype if it didn't echo
    logout_first    => 20,    # wait for the first LOGOUT line
    logout_quiet    => 5,     # done once no new LOGOUT for this long
    logout_max      => 45,    # cap on the whole logout step
    shutdown        => 100,   # 'shut' -> BCE prompt
    bce_attention   => 3,     # optional M-> after ESC at BCE
    die_wait        => 10,    # 'die' -> "really wish bce to die?"
    sim_wait        => 15,    # 'y'   -> sim> prompt
    exit            => 20,    # 'quit' -> dps8 process gone
);

# Console patterns. If a step times out, check $console_log for the exact
# wording your system printed and adjust the pattern.
my $RE_MPROMPT = qr/M->/;
my $RE_BCE     = qr/bce \(\w+\) [\d.]+:/;
# Asked only when users/daemons are still logged in, e.g.
#   "shutdown: 6 users still on. Do you want to shut down?     M-> "
# The M-> prompt follows on the same line, so this must match the question
# itself, not a line end.
my $RE_CONFIRM = qr/Do you want to shut down\?/i;
my $RE_DIE_Q   = qr/really wish bce to die/i;
my $RE_RELEASE = qr/CONSOLE: RELEASED/;        # ESC on a live read releases it
my $RE_LOGOUT  = qr/\bas\s+LOGOUT\b/;          # " 1103  as   LOGOUT   ..."
my $RE_SIM     = qr/sim>/;

# --- tmux access ---
# Run tmux as the server's owner (_multics). This tmux server can treat root
# as a read-only client and refuse send-keys ("client is read-only").
# su hands everything after -c's script to sh as "$0" "$@", so arguments
# pass through unquoted and unmangled. (On OpenBSD su, -c after the login
# name is a shell argument, not a login class.)
die "shutdown_multics: no such user $target_user\n"
    unless defined getpwnam $target_user;
my @TMUX = ('/usr/bin/su', '-s', '/bin/sh', $target_user,
            '-c', 'exec "$0" "$@"', $tmux_bin);

sub tmux     { return system(@TMUX, @_) == 0 }
sub send_key { tmux('send-keys', '-t', $pane, @_) }
sub send_line {
    my ($text) = @_;
    tmux('send-keys', '-t', $pane, '-l', $text);    # literal text
    tmux('send-keys', '-t', $pane, 'Enter');
}

# Type a command at a prompt we've just seen. Keys that arrive before the
# console's read is actually posted are silently dropped, so pause first,
# then confirm the console reacted ($expect_re: its echo by default, or the
# response it should produce), and retype if it didn't. With $reattach (for
# commands typed at M->), re-acquire the console before each retype, in case
# the read was released before our keys landed.
sub send_cmd {
    my ($text, $expect_re, $timeout, $reattach) = @_;
    $expect_re //= qr/\Q$text\E/;
    $timeout   //= $T{echo};
    for my $try (1 .. $T{type_tries}) {
        if ($try > 1 && $reattach) {
            attention() or return 0;
        }
        sleep $T{settle};
        send_line($text);
        return 1 if wait_for($timeout, $expect_re) >= 0;
        print "   no response to '$text' (try $try), retyping...\n";
    }
    return 0;
}

sub sim_running { return system($pgrep_bin, '-q', '-xf', $pexp) == 0 }

sub session_exists {
    my $pid = fork() // return 0;
    if ($pid == 0) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        exec @TMUX, 'has-session', '-t', $session;
        exit 1;
    }
    waitpid($pid, 0);
    return $? == 0;
}

sub capture_pane {
    open(my $fh, '-|', @TMUX, 'capture-pane', '-p', '-t', $pane) or return '';
    local $/;
    my $out = <$fh> // '';
    close $fh;
    return $out;
}

sub snapshot {
    print "\n--- [ MULTICS CONSOLE SNAPSHOT ] ---\n", capture_pane(),
          "-------------------------------------\n\n";
}

# --- console log reader ---
my ($log_pos, $buf) = (0, '');

sub pump {
    open(my $fh, '<:raw', $console_log) or return;
    seek($fh, $log_pos, 0);
    local $/;
    my $chunk = <$fh>;
    close $fh;
    return unless defined $chunk && length $chunk;
    $log_pos += length $chunk;
    $chunk =~ s/\e\[[0-9;?]*[A-Za-z]//g;    # strip terminal escapes
    $chunk =~ s/\r//g;
    $buf .= $chunk;
}

sub drain { pump(); $buf = '' }

# Wait until one of @pats appears in new console output. Returns the index
# of the earliest match, or -1 on timeout. Consumes output up to the match.
sub wait_for {
    my ($timeout, @pats) = @_;
    my $deadline = time + $timeout;
    while (1) {
        pump();
        my ($best, $start, $end);
        for my $i (0 .. $#pats) {
            next unless $buf =~ $pats[$i];
            if (!defined $start || $-[0] < $start) {
                ($best, $start, $end) = ($i, $-[0], $+[0]);
            }
        }
        if (defined $best) {
            substr($buf, 0, $end, '');
            return $best;
        }
        return -1 if time >= $deadline;
        sleep 0.25;
    }
}

sub fail {
    my ($msg) = @_;
    print "FAILED: $msg\n";
    snapshot();
    tmux('pipe-pane', '-t', $pane);    # stop logging
    print "Simulator left running; finish manually on the console.\n",
          "Full console output from this attempt: $console_log\n";
    exit 1;
}

# ESC toggles the console: it grabs attention (M->) when idle, but releases a
# read that is already pending (CONSOLE: RELEASED). If we hit a live read,
# just press ESC again to get a fresh one.
sub attention {
    for my $try (1 .. $T{attention_tries}) {
        drain();
        send_key('Escape');
        my $r = wait_for($T{attention}, $RE_MPROMPT, $RE_RELEASE);
        return 1 if $r == 0;
        if ($r == 1) {
            print "   released a pending read; pressing ESC again...\n";
            next;
        }
        print "   no M-> prompt yet (try $try), retrying...\n";
    }
    return 0;
}

# Console output since byte offset $from in the log (escapes stripped).
sub log_since {
    my ($from) = @_;
    open(my $fh, '<:raw', $console_log) or return '';
    seek($fh, $from, 0);
    local $/;
    my $text = <$fh> // '';
    close $fh;
    $text =~ s/\e\[[0-9;?]*[A-Za-z]//g;
    return $text;
}

# After 'logout * * *', the console says Ready right away but the LOGOUT
# lines trickle in afterwards. Count them straight from the log file since
# the command was sent ($mark), so nothing else can consume them first, and
# call it done once the count stops changing.
sub wait_for_logouts {
    my ($mark) = @_;
    my $end   = time + $T{logout_max};
    my $last  = 0;
    my $since = time;
    while (time < $end) {
        my $n = () = log_since($mark) =~ /$RE_LOGOUT/g;
        ($last, $since) = ($n, time) if $n != $last;
        last if time - $since >= ($last ? $T{logout_quiet} : $T{logout_first});
        sleep 0.5;
    }
    drain();    # those lines are dealt with; start the next step clean
    return $last;
}

# Work out where the console is right now, so a re-run after a partial
# shutdown picks up from the right stage.
sub detect_state {
    my @lines = grep { /\S/ } split /\n/, capture_pane();
    my $last = @lines ? $lines[-1] : '';
    return 'sim' if $last =~ /sim>\s*$/;
    return 'bce' if $last =~ $RE_BCE;
    return 'multics';
}

# --- MAIN ---
print "Initiating Multics shutdown sequence...\n";

unless (sim_running()) {
    print "Simulator is not running; nothing to do.\n";
    exit 0;
}
fail("tmux session '$session' not found") unless session_exists();

unlink $console_log;
tmux('pipe-pane', '-t', $pane, "exec cat > $console_log")
    or fail("could not start console logging");
for (1 .. 40) { last if -e $console_log; sleep 0.05 }

my $state = detect_state();
print "-> Console appears to be at stage: $state\n";

if ($state eq 'multics') {
    if ($logout_daemons) {
        print "-> Requesting operator attention (ESC)...\n";
        attention() or fail("no M-> prompt after ESC");

        print "-> Logging out daemons (logout * * *)...\n";
        pump();
        my $mark = $log_pos;
        # Accepted if it echoes, or if its effects show up (Ready / LOGOUT),
        # so a slow echo doesn't trigger a needless retype.
        send_cmd('logout * * *',
                 qr/logout \* \* \*|\bReady\b|$RE_LOGOUT/, undef, 1)
            or fail("'logout * * *' was not accepted by the console");
        my $n = wait_for_logouts($mark);
        print "   $n daemon(s) logged out.\n";
    }

    print "-> Requesting operator attention (ESC)...\n";
    attention() or fail("no M-> prompt after ESC");

    print "-> Sending 'shut'...\n";
    send_cmd('shut', undef, undef, 1)
        or fail("'shut' was not accepted by the console");

    my $deadline = time + $T{shutdown};
    my $answers  = 0;
    while (1) {
        my $left = $deadline - time;
        fail("timed out waiting for BCE prompt after 'shut'") if $left <= 0;
        my $r = wait_for($left, $RE_BCE, $RE_CONFIRM);
        fail("timed out waiting for BCE prompt after 'shut'") if $r < 0;
        last if $r == 0;
        fail("too many confirmation prompts") if ++$answers > 5;
        print "-> Answering 'Do you want to shut down?' (y)...\n";
        # Echo appears after the M-> that follows the question.
        send_cmd('y', qr/M->[ \t]*y\b/)
            or fail("answer 'y' was not accepted by the console");
    }
    print "-> Multics is down; at BCE.\n";
    $state = 'bce';
}

if ($state eq 'bce') {
    drain();
    print "-> Requesting attention at BCE (ESC)...\n";
    send_key('Escape');
    wait_for($T{bce_attention}, $RE_MPROMPT);    # fine if it doesn't appear

    # Here we wait for BCE's question rather than the echo, because the
    # question itself contains the word "die".
    print "-> Sending 'die'...\n";
    send_cmd('die', $RE_DIE_Q, $T{die_wait})
        or fail("no 'really wish bce to die' prompt");

    print "-> Confirming (y)...\n";
    send_cmd('y', $RE_SIM, $T{sim_wait})
        or fail("no sim> prompt after BCE die");
    $state = 'sim';
}

if ($state eq 'sim') {
    print "-> Quitting simulator...\n";
    sleep $T{settle};
    send_line('quit');
    my $deadline = time + $T{exit};
    my $resent   = 0;
    while (sim_running()) {
        fail("simulator still running after 'quit'") if time > $deadline;
        if (!$resent && time > $deadline - $T{exit} / 2) {
            print "   still running, retyping 'quit'...\n";
            send_line('quit');
            $resent = 1;
        }
        sleep 0.5;
    }
}

print "SUCCESS: Multics shut down cleanly; simulator has exited.\n";
exit 0;

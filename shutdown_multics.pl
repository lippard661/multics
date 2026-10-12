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

# --- CONFIGURATION ---
my $tmux_bin    = '/usr/bin/tmux';
my $pgrep_bin   = '/usr/bin/pgrep';
my $target_user = '_multics';
my $session     = 'multics';
my $pane        = "$session:0.0";
my $pexp        = '.*dps8 /home/_multics/MR12.8_boot.ini';    # same as rc script
my $console_log = '/home/_multics/.shutdown-console.log';      # kept for debugging

# Per-step timeouts in seconds. The worst case total is about 285 s, which
# stays under daemon_timeout=300 in /etc/rc.d/multics.
my %T = (
    attention       => 5,     # wait for M-> after each ESC
    attention_tries => 4,     # ESC retries if daemon output delays the prompt
    shutdown        => 180,   # 'shut' -> BCE prompt (logging out daemons, etc.)
    bce_attention   => 3,     # optional M-> after ESC at BCE
    die_prompt      => 30,    # 'die' -> "really wish bce to die?"
    sim_prompt      => 30,    # 'y'   -> sim> prompt
    exit            => 20,    # 'quit' -> dps8 process gone
);

# Console patterns. If a step times out, check $console_log for the exact
# wording your system printed and adjust the pattern.
my $RE_MPROMPT = qr/M->/;
my $RE_BCE     = qr/bce \(\w+\) [\d.]+:/;
my $RE_CONFIRM = qr/\b(?:really|sure|want to|continue|proceed)\b[^\n]*\?[ \t]*$/im;
my $RE_DIE_Q   = qr/really wish bce to die/i;
my $RE_SIM     = qr/sim>/;

# --- tmux access ---
# Root can talk to the _multics tmux server directly through its socket,
# which avoids su and shell quoting entirely.
my $uid = (getpwnam $target_user)[2];
die "shutdown_multics: no such user $target_user\n" unless defined $uid;
my @TMUX = ($tmux_bin, '-S', "/tmp/tmux-$uid/default");

sub tmux     { return system(@TMUX, @_) == 0 }
sub send_key { tmux('send-keys', '-t', $pane, @_) }
sub send_line {
    my ($text) = @_;
    tmux('send-keys', '-t', $pane, '-l', $text);    # literal text
    tmux('send-keys', '-t', $pane, 'Enter');
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

sub attention {
    for my $try (1 .. $T{attention_tries}) {
        drain();
        send_key('Escape');
        return 1 if wait_for($T{attention}, $RE_MPROMPT) >= 0;
        print "   no M-> prompt yet (try $try), retrying...\n";
    }
    return 0;
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
    print "-> Requesting operator attention (ESC)...\n";
    attention() or fail("no M-> prompt after ESC");

    print "-> Sending 'shut'...\n";
    send_line('shut');

    my $deadline = time + $T{shutdown};
    my $answers  = 0;
    while (1) {
        my $left = $deadline - time;
        fail("timed out waiting for BCE prompt after 'shut'") if $left <= 0;
        my $r = wait_for($left, $RE_BCE, $RE_CONFIRM);
        fail("timed out waiting for BCE prompt after 'shut'") if $r < 0;
        last if $r == 0;
        fail("too many confirmation prompts") if ++$answers > 5;
        print "-> Answering confirmation prompt (y)...\n";
        send_line('y');
    }
    print "-> Multics is down; at BCE.\n";
    $state = 'bce';
}

if ($state eq 'bce') {
    drain();
    print "-> Requesting attention at BCE (ESC)...\n";
    send_key('Escape');
    wait_for($T{bce_attention}, $RE_MPROMPT);    # fine if it doesn't appear

    print "-> Sending 'die'...\n";
    send_line('die');
    wait_for($T{die_prompt}, $RE_DIE_Q) >= 0
        or fail("no 'really wish bce to die' prompt");

    print "-> Confirming (y)...\n";
    send_line('y');
    wait_for($T{sim_prompt}, $RE_SIM) >= 0
        or fail("no sim> prompt after BCE die");
    $state = 'sim';
}

if ($state eq 'sim') {
    print "-> Quitting simulator...\n";
    send_line('quit');
    my $deadline = time + $T{exit};
    while (sim_running()) {
        fail("simulator still running after 'quit'") if time > $deadline;
        sleep 0.5;
    }
}

print "SUCCESS: Multics shut down cleanly; simulator has exited.\n";
exit 0;

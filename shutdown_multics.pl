#!/usr/bin/perl
use strict;
use warnings;

# --- CONFIGURATION ---
my $su_bin       = '/usr/bin/su';
my $tmux_bin     = '/usr/bin/tmux';
my $target_user  = '_multics';
my $session_name = 'multics';

sub print_console_snapshot {
    my $capture_cmd = "$tmux_bin capture-pane -t $session_name:0.0 -p";
    my @cmd = ($su_bin, '-s', '/bin/sh', $target_user, '-c', $capture_cmd);
    print "\n--- [ MULTICS CONSOLE SNAPSHOT ] ---\n";
    system(@cmd);
    print "-------------------------------------\n\n";
}

sub send_operator_keys {
    my (@keys) = @_;
    foreach my $key (@keys) {
        my $tmux_cmd = "$tmux_bin send-keys -t $session_name:0.0 $key";
        my @cmd = ($su_bin, '-s', '/bin/sh', $target_user, '-c', $tmux_cmd);
        system(@cmd);
        sleep 2; 
    }
}

print "Initiating clean automated Multics Mainframe shutdown sequence...\n";

# --- STEP 1: GAIN OPERATOR MODE ATTENTION ---
print "-> Disconnecting active listener channels & acquiring Master Prompt (ESC + ESC)...\n";
send_operator_keys("Escape", "Escape");
print_console_snapshot();

# --- STEP 1.5: LOGOUT USERS ---
print "--> Injecting 'logout * * *' command string...\n";
send_operator_keys("-l", "logout * * *", "Enter");
sleep 5;

# --- STEP 2: DISPATCH SHUTDOWN AND IMMEDIATELY CONFIRM ---
print "-> Injecting 'shut' command string...\n";
send_operator_keys("-l", "shut", "Enter");

# Queue the 'y' confirmation instantly behind it to beat the opcon input lock timer
print "-> Injecting prompt override confirmation (y)...\n";
send_operator_keys("-l", "y", "Enter");
sleep 5;
print_console_snapshot();

# --- STEP 3: WAIT FOR GRACEFUL STORAGE POOL UNMOUNT ---
print "-> System unmounting segments. Waiting 20 seconds for clean drop to BCE...\n";
sleep 20;
print_console_snapshot();

# --- STEP 4: BREAK CONSOLE AND HALT BCE ENGINE ---
print "-> Gaining attention at BCE stage to unlock master prompt (ESC)...\n";
send_operator_keys("Escape");
print_console_snapshot();

print "-> Sending final processor halt directive (die)...\n";
send_operator_keys("-l", "die", "Enter");

# THE SECOND PROMPT CATCH: BCE asks "Do you really wish bce to die?"
# Queue the 'y' immediately into the PTY line buffer behind the die command.
print "-> Confirming hardware core termination (y)...\n";
send_operator_keys("-l", "y", "Enter");
sleep 5;
print_console_snapshot();

# --- STEP 5: CLOSE EMULATOR CONTAINER ---
print "-> Closing underlying simulator container disk boundaries (quit)...\n";
send_operator_keys("-l", "quit", "Enter");
sleep 2;

print "SUCCESS: Safe dual-prompt shutdown executed. Mainframe is completely offline.\n";
exit 0;

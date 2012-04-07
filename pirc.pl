#!/usr/bin/perl

############################################################################
## This file is part of pIRC.                                             ##
##                                                                        ##
## pIRC is free software: you can redistribute it and/or modify           ##
## it under the terms of the GNU General Public License as published by   ##
## the Free Software Foundation, either version 3 of the License, or      ##
## (at your option) any later version.                                    ##
##                                                                        ##
## pIRC is distributed in the hope that it will be useful,                ##
## but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
## GNU General Public License for more details.                           ##
##                                                                        ##
## You should have received a copy of the GNU General Public License      ##
## along with pIRC. If not, see <http://www.gnu.org/licenses/>.           ##
############################################################################

package main;

# Our dependencies
use strict;
use warnings;
use IO::Socket::INET;
use Term::ANSIColor;
use POSIX qw(setsid);
# Load our bot module
use bot::pIRCbot;

# Stuff for if we're running as a daemon (often)
my $daemon = 0;
my $pidfile = '/var/run/pirc.pid';
my $logfile = '/var/log/pirc.log';

# Other variables
my $ver = '0.6';
my $cref;

$SIG{INT}=\&CleanExit;
sub CleanExit
{
    SocketSend("QUIT :Don't let them kill me! :[");
    exit(0);
}

# Check for switches (such as ./pirc.pl --daemon)
foreach(@ARGV)
{
    if ($_ eq '-D' or $_ eq '--daemon')
    {
        $daemon = 1;
    }
    elsif ($_ eq '-h' or $_ eq '--help')
    {
        print "-D, --daemon\t\tRun pIRC as a Daemon (in the background)\n";
        print "-k, --kill\t\tCleanly disconnect and close an instance (SIGINT)\n";
        print "-h, --help\t\tShow this help menu\n";
        exit(0);
    }
    elsif ($_ eq '-k' or $_ eq '--kill')
    {
        # Send SIGINT to the pid (from the pid file) and exit
        open(PIDFILE, '<', $pidfile);
        kill('INT', <PIDFILE>);
        close(PIDFILE);
        exit(0);
    }
    else
    {
        print "invalid option -- '$_'\n";
        print "Try --help for more information.\n";
        exit(1);
    }
}

# Fork, write the PID to $pidfile, exit
# In the child redirect stdout/stderr to $logfile
if ($daemon)
{
    my $pid = fork();
    die('Fork failed') if (! defined($pid));
    if ($pid > 0)
    {
        if (open(PIDFILE, '>', $pidfile))
        {
            syswrite(PIDFILE, $pid . "\n");
            close(PIDFILE);
        }
        else
        {
            print '[' . color 'RED BOLD'; print '!!!'; print color 'RESET'; print '] ';
            print "Cannot write to PID file!\n";
        }
        exit(0);
    }
    open(STDIN, '<', '/dev/null');
    open(STDOUT, '>', $logfile);
    open(STDERR, '>', $logfile);
    setsid();
}

print '[' . color 'RED BOLD'; print '!!!'; print color 'RESET'; print '] ';
print "Starting pIRC v$ver\n";

# Make a connection to the IRC Server
print '[' . color 'YELLOW BOLD'; print '---'; print color 'RESET'; print '] ';
print "Connecting to $host on $port...\n";
my $socket = new IO::Socket::INET('PeerAddr' => $host, 'PeerPort' => $port, 'Proto' => 'tcp');
if (! $socket)
{
    print '[' . color 'YELLOW BOLD'; print '---'; print color 'RESET'; print '] ';
    print "Connection failed: $!\n";
    exit(1);
}
print '[' . color 'YELLOW BOLD'; print '---'; print color 'RESET'; print '] ';
print "Connected!\n";

# This will handle sending our data
sub SocketSend
{
    syswrite($socket, join('', @_) . "\r\n");
    print '['; print color 'GREEN BOLD'; print '>>>'; print color 'RESET'; print '] ';
    print join('', @_) . "\n";
}

# We split the packet up for IRC command processing (Thanks to Aaron Jones for the code)
sub ProcessPacket
{
    my ($packet) = @_;
    my ($source, $extra);
    return unless ($packet);
    # Preprocess the IRC packet (split it up into :source, COMMANDTYPE, args[], ... :extra)
    if ($packet =~ m/^\:(.+?) (.+)$/) { $source = $1; $packet = $2; }
    if ($packet =~ m/^(.+?) \:(.+)$/) { $packet = $1; $extra = $2; }
    my ($cmdtype, @args) = split(/\s+/, $packet);
    # Now take action based on its type
    $cref = main->can(uc('command_' . $cmdtype));
    if (ref($cref) eq 'CODE') { &{$cref}($source, \@args, $extra); }
}

# Must respond to pings
sub COMMAND_PING
{
    my ($source, $args, $extra) = @_;
    SocketSend("PONG : $extra");
}

# Pass invites to bot/pIRCbot.pm
sub COMMAND_INVITE
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel
    
    $cref = bot::pIRCbot->can('GotInvite');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $extra); }
}

# Pass joins to bot/pIRCbot.pm
sub COMMAND_JOIN
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel
    $cref = bot::pIRCbot->can('GotJoin');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $extra); }
}

# Pass parts to bot/pIRCbot.pm
sub COMMAND_PART
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel, $reason
    $cref = pIRCbot->can('GotPart');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $args->[0], $extra); }
}

# Pass messages to bot/pIRCbot.pm
sub COMMAND_PRIVMSG
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Check if it's a channel message or a private one
    if ($args->[0] =~ m/^#/)
    {
        # Pass it with the variables; $nick, $address, $channel, $message
        $cref = bot::pIRCbot->can('GotChannelMessage');
        if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $args->[0], $extra); }
    }
    else
    {
        # Pass it with the variables; $nick, $address, $message
        $cref = bot::pIRCbot->can('GotPrivateMessage');
        if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $extra); }
    }
}

# Pass quits to bot/pIRCbot.pm
sub COMMAND_QUIT
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel, $reason
    $cref = bot::pIRCbot->can('GotQuit');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $args->[0], $extra); }
}

# Pass kicks to bot/pIRCbot.pm
sub COMMAND_KICK
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel, $kickee, $reason
    $cref = bot::pIRCbot->can('GotKick');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $args->[0], $args->[1], $extra); }
}

# Pass nick changes to bot/pIRCbot.pm
sub COMMAND_NICK
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $newnick
    $cref = bot::pIRCbot->can('GotNick');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $extra); }
}

# We need to send these or the server will just drop us :[
SocketSend("USER $username 8 * :pIRC v$ver");
SocketSend("NICK $nickname");
SocketSend("MODE $nickname $usermode") if $usermode;
SocketSend("JOIN $autojoin") if $autojoin;

# Process incoming data
while (my $line = <$socket>)
{
    $line =~ s/\s+$//g;
    print '['; print color 'BLUE BOLD'; print '<<<'; print color 'RESET'; print '] ';
    print "$line\n";
    ProcessPacket($line);
}
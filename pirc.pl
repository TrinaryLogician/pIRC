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
use strict;
use warnings;
use POSIX;
use IO::Socket::IP;
use IO::Socket::SSL;
use Module::Reload::Selective;
use Getopt::Std;
use modules::logging;
use modules::cmodes;
use bot::pIRCbot;
$Module::Reload::Selective::Options->{"ReloadOnlyIfEnvVarsSet"} = 0;
my %cmdopts;

# Variables important to pIRC
my $ver = '1.0.7';
my $socket;
my $cref;
my $pidfile = './pirc.pid';
my $logfile = './pirc.log';
my $currnick;           # Keep track of our CURRENT nick (for nick changes etc)
my %currchans = ( );    # Keep track of channels we are currently in

# SSL/TLS Stuff
my %ssloptions;
$ssloptions{'SSL_version'} = 'TLSv1';
$ssloptions{'SSL_ca_path'} = '/etc/ssl/certs/';
$ssloptions{'SSL_hostname'} = $host;
$ssloptions{'SSL_verify_mode'} = 1;
$ssloptions{'SSL_verifycn_name'} = $host;
$ssloptions{'SSL_verifycn_scheme'} = 'www';

$SIG{INT}=\&GotSIGINT;
sub GotSIGINT
{
    SocketSend("QUIT :Don't let them kill me! :[");
    exit(0);
}
$SIG{HUP}=\&GotSIGHUP;
sub GotSIGHUP
{
    ReloadBot();
}

# Print our help message for command line options
sub ShowHelp
{
    print "\t-d\tRun pIRC as a Daemon (in the background)\n";
    print "\t-k\tCleanly disconnect and close an instance (SIGINT)\n";
    print "\t-r\tSend the reload signal (SIGHUP) to pIRC to reload the\n";
    print "\t\tbot module\n";
    print "\t-q\tBe quieter with output/logging\n";
    print "\t-h\tShow this help menu\n";
    exit(1);
}

if (! getopts('dkrqh', \%cmdopts)) { &ShowHelp(); }

if ($cmdopts{'k'})
{
    # Send SIGINT to the pid (from the pid file) and exit
    open(PIDFILE, '<', $pidfile);
    my $pid = <PIDFILE>;
    close(PIDFILE);
    if ($pid && $pid =~ m/[0-9]/)
    {
        kill('INT', $pid);
        print "Killed pIRC - PID: $pid\n";
        exit(0);
    }
    else
    {
        print "No PID found. Exiting.\n";
        exit(1);
    }
}

if ($cmdopts{'r'})
{
    # Send SIGHUP to the pid (from the pid file) and exit
    open(PIDFILE, '<', $pidfile);
    my $pid = <PIDFILE>;
    close(PIDFILE);
    if ($pid && $pid =~ m/[0-9]/)
    {
        kill('HUP', $pid);
        print "Sent reload signal to pIRC\n";
        exit(0);
    }
    else
    {
        print "No PID found. Exiting.\n";
        exit(1);
    }
}

if ($cmdopts{'h'})
{
    ShowHelp();
}

# Fork, write the PID to $pidfile, exit
# In the child redirect stdout/stderr to $logfile
if ($cmdopts{'d'})
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
            LogMessage('other', "Cannot write to PID file!");
        }
        exit(0);
    }
    open(STDIN, '<', '/dev/null');
    open(STDOUT, '>', $logfile);
    open(STDERR, '>', $logfile);
    setsid();
}

LogMessage('other', "Starting pIRC v$ver");

# This will handle sending our data
sub SocketSend
{
    syswrite($socket, join('', @_) . "\r\n");
    if (! $cmdopts{'q'}) {LogMessage('send', join('', @_));}
}

# We split the packet up for IRC command processing (Thanks to Aaron Jones for the code)
sub ProcessPacket
{
    my ($packet) = @_;
    my ($source, $extra);
    my $line = $packet;
    return unless ($packet);
    # Preprocess the IRC packet (split it up into :source, COMMANDTYPE, args[], ... :extra)
    if ($packet =~ m/^\:(.+?) (.+)$/) { $source = $1; $packet = $2; }
    if ($packet =~ m/^(.+?) \:(.+)$/) { $packet = $1; $extra = $2; }
    my ($cmdtype, @args) = split(/\s+/, $packet);
    # Print the packet (excluding pings)
    if (! $cmdopts{'q'} && lc($cmdtype) ne 'ping') {LogMessage('receive', $line);}
    # Now take action based on its type
    $cref = main->can(uc('command_' . $cmdtype));
    if (ref($cref) eq 'CODE') { &{$cref}($source, \@args, $extra); }
}

# Must respond to pings
sub COMMAND_PING
{
    my ($source, $args, $extra) = @_;
    syswrite($socket, "PONG :$extra\r\n");
}

# This happens once we're all connected to use it for auto stuff
sub COMMAND_266
{
    SocketSend("MODE $nickname $usermode") if $usermode;
    SocketSend("JOIN $autojoin") if $autojoin;
    
    # Join channels we were in (in case we got disconnected)
    foreach my $key ( keys %currchans )
    {
        SocketSend("JOIN $key");
    }
}

# This captures the channel mode string after we join
sub COMMAND_324
{
    my ($source, $args, $extra) = @_;
    if ($args->[3]){cMode($args->[1], $args->[2], $args->[3]); return;}
    cMode($args->[1], $args->[2]);
}

# This captures the NAMES list for a channel
sub COMMAND_353
{
    my ($source, $args, $extra) = @_;
    uMode($args->[2], $extra);
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
    
    # If WE joined
    if ($source[0] eq $nickname)
    {
        NewChan($extra);
        $currchans{$extra} = 1;
        SocketSend("MODE $extra");
    }
    # Otherwise if it's someone else joining
    else
    {
        SocketSend("NAMES $extra");
    }
    
    # Pass it with the variables; $nick, $address, $channel
    $cref = bot::pIRCbot->can('GotJoin');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $extra); }
}

# Pass parts to bot/pIRCbot.pm
sub COMMAND_PART
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    
    if ($source[0] eq $nickname)
    {
        delete($channels{lc($args->[0])});
        delete($currchans{$args->[0]});
    }
    else
    {
        delete($channels{lc($args->[0])}{'nicks'}{lc($source[0])});
    }
    
    # Pass it with the variables; $nick, $address, $channel, $reason
    $cref = bot::pIRCbot->can('GotPart');
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
    
    # If it's NOT us quitting (if it is it won't matter, the array will be destroyed)
    if ($source[0] ne $nickname)
    {
        # Loop and remove them from each channel they were in
        foreach my $key ( keys %channels )
        {
            if ($channels{$key}{'nicks'}{lc($source[0])})
            {
                delete($channels{$key}{'nicks'}{lc($source[0])});
            }
        }
    }
    
    # Pass it with the variables; $nick, $address, $channel, $reason
    $cref = bot::pIRCbot->can('GotQuit');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $args->[0], $extra); }
}

# Pass kicks to bot/pIRCbot.pm
sub COMMAND_KICK
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    
    if ($source[0] eq $nickname)
    {
        delete($channels{lc($args->[0])});
        delete($currchans{$args->[0]});
    }
    else
    {
        delete($channels{lc($args->[0])}{'nicks'}{lc($source[0])});
    }
    
    # Pass it with the variables; $nick, $address, $channel, $kickee, $reason
    $cref = bot::pIRCbot->can('GotKick');
    if (ref($cref) ne 'CODE') {return 0;}
    
    # Split up a nick list by commas (or pass it on if its not a list)
    foreach(split(/,/, $args->[1]))
    {
        &{$cref}($source[0], $source[1], $args->[0], $_, $extra);
    }
}

# Pass nick changes to bot/pIRCbot.pm
sub COMMAND_NICK
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    if ($source[0] eq $nickname)
    {
        $currnick = $extra;
        $nickname = $currnick;
    }
    else
    {
        # Update our modes listing
        foreach my $key ( keys %channels )
        {
            if ($channels{$key}{'nicks'}{lc($source[0])})
            {
                delete($channels{$key}{'nicks'}{lc($source[0])});
                SocketSend("NAMES $key");
            }
        }
    }
    
    # Pass it with the variables; $nick, $address, $newnick
    $cref = bot::pIRCbot->can('GotNick');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $extra); }
}

# Pass NOTICEs to bot/pIRCbot.pm
sub COMMAND_NOTICE
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $message
    $cref = bot::pIRCbot->can('GotNotice');
    if (ref($cref) eq 'CODE') { &{$cref}($source[0], $source[1], $extra); }
}

# Refresh our MODEs
sub COMMAND_MODE
{
    my ($source, $args, $extra) = @_;
    if ($args->[0] =~ m/^#/)
    {
        if (! $args->[2])
        {
            SocketSend("MODE $args->[0]");
        }
        else
        {
            SocketSend("NAMES $args->[0]");
        }
    }
}

# Make sure we don't annoy Opers by rejoining after a /kill
sub COMMAND_KILL
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    $extra =~ m/\((.+?)\)$/;
    LogMessage('connection', $1);
    exit(2);
}

# Reload the bot module
sub ReloadBot
{
    my $botpath = './bot/pIRCbot';
    if (-e $botpath . ".pm" && -r $botpath . ".pm")
    {
        my $syncheck = `perl -c $botpath.pm 2>&1`;
                
        if ($syncheck =~ /syntax ok/i)
        {
            Module::Reload::Selective->reload($botpath);
            $nickname = $currnick if $currnick;
            %channels = ( );
            foreach my $key ( keys %currchans )
            {
                NewChan($key);
                SocketSend("MODE $key");
                SocketSend("NAMES $key");
            }
            return 'success';
        }
        else
        {
            $syncheck =~ m/at ([^ ]+) line (\d+)/;
            return $syncheck;
        }
    }
    else
    {
        return 'file';
    }
}

# Infinite loop to keep us connected
for(;;)
{
    # Make a connection to the IRC Server
    LogMessage('connection', "Connecting to $host:$port...");
    $socket = new IO::Socket::IP('PeerAddr' => $host, 'PeerPort' => $port);
    unless ($socket)
    {
        LogMessage('connection', "Could not establish a connection to $host:$port");
        exit(1);
    }
    LogMessage('connection', "Successfully connected to $host (" . $socket->peerhost() . ") on port " . $socket->peerport());
    
    # Start SSL/TLS if it's enabled
    if ($usessl)
    {
        LogMessage('Attempting TLSv1 negotiation...');
        IO::Socket::SSL->start_SSL($socket, %ssloptions );
        unless (ref($socket) eq 'IO::Socket::SSL')
        {
            LogMessage('connection', 'TLSv1 negotiation failed! Either this is a plain-text port or this servers SSL certificate is not trusted.');
            exit(1);
        }
        LogMessage('connection', 'Successfully negotiated TLSv1 session, using cipher ' . $socket->get_cipher());
    }
    else
    {
        LogMessage('connection', 'WARNING: Using a plain-text connection is NOT recommended.');
    }
    
    # We need to send these or the server will just drop us :[
    SocketSend("USER $username 8 * :pIRC v$ver");
    SocketSend("NICK $nickname");
    SocketSend("PASS $nickpass") if $nickpass;
    
    # Process incoming data
    while (my $line = <$socket>)
    {
        $line =~ s/\s+$//g;
        ProcessPacket($line);
    }

    # If we get to here, we've been disconnected
    if ($reconn)
    {
        LogMessage('connection', "Connection lost, reconnecting in 5 seconds...");
        %channels = ();
        sleep 5;
    }
    else
    {
        LogMessage('connection', "Connection lost (reconnecting is disabled).");
        exit(0);
    }
}
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
my $ver = '0.2';

# Our dependencies
use strict;
use warnings;
use IO::Socket::INET;
use Term::ANSIColor;
# Load our bot module
use pIRCbot;

# Make a connection to the IRC Server
my $socket = new IO::Socket::INET('PeerAddr' => $host, 'PeerPort' => $port, 'Proto' => 'tcp');
if (! $socket)
{
    print '[' . color 'RED BOLD'; print '!!!'; print color 'RESET'; print '] ';
    print "Connection failed: $!\n"; exit();
}

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
    my ($source, $extra, $cref);
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
    SocketSend('PONG :', $extra);
}

# Pass invites to pIRCbot.pm
sub COMMAND_INVITE
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel
    pIRCbot::GotInvite($source[0], $source[1], $extra);
}

# Pass joins to pIRCbot.pm
sub COMMAND_JOIN
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel
    pIRCbot::GotJoin($source[0], $source[1], $extra);
}

# Pass parts to pIRCbot.pm
sub COMMAND_PART
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel, $reason
    pIRCbot::GotPart($source[0], $source[1], $args, $extra);
}

# Pass messages to pIRCbot.pm
sub COMMAND_PRIVMSG
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Check if it's a channel message or a private one
    if ($args =~ m/^#/)
    {
        # Pass it with the variables; $nick, $address, $channel, $message
        pIRCbot::GotChannelMessage($source[0], $source[1], $args, $extra);
    }
    else
    {
        # Pass it with the variables; $nick, $address, $message
        pIRCbot::GotPrivateMessage($source[0], $source[1], $extra);
    }
}

# Pass quits to pIRCbot.pm
sub COMMAND_QUIT
{
    my ($source, $args, $extra) = @_;
    my @source = split('!', $source);
    # Pass it with the variables; $nick, $address, $channel, $reason
    pIRCbot::GotQuit($source[0], $source[1], $args, $extra);
}

# We need to send these or the server will just drop us :[
SocketSend("USER " . $username . " 8 * :pIRC v$ver");
SocketSend("NICK " . $nickname);
SocketSend("JOIN " . $autojoin) if $autojoin;

# Process incoming data
while (my $line = <$socket>)
{
    $line =~ s/\s+$//g;
    print '['; print color 'BLUE BOLD'; print '<<<'; print color 'RESET'; print '] ';
    print "$line\n";
    ProcessPacket($line);
}
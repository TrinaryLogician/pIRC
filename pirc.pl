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
our $ver = '0.1';

# Our dependencies
use strict;
use warnings;
use IO::Socket::INET;
use Term::ANSIColor;

# Variables for server connection, change this to reflect your bot info
my $host = 'irc.serenia.net';
my $port = '6667';
my $nickname = 'pIRC';
my $username = 'pIRC';
my $realname = 'pIRC v' . $ver;
my $autojoin = '#pIRC';   # Leave blank for none

# Make a connection to the IRC Server
my $socket = new IO::Socket::INET('PeerAddr' => $host, 'PeerPort' => $port, 'Proto' => 'tcp');
if (! $socket)
{
    print '[' . color 'red bold'; print '!!!'; print color 'reset'; print '] ';
    print "Connection failed: $!\n"; exit();
}

# This will handle sending our data
sub SocketSend
{
    syswrite($socket, join('', @_) . "\r\n");
    print '['; print color 'green bold';
    print '>>>'; print color 'reset';
    print '] ' . join('', @_) . "\n";
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

# We need to send these or the server will just drop us :[
SocketSend("USER $username 8 * :$realname");
SocketSend("NICK $nickname");
SocketSend("JOIN $autojoin") if $autojoin;

# Process incoming data
while (my $line = <$socket>)
{
    $line =~ s/\s+$//g;
    print '['; print color 'blue bold';
    print '<<<'; print color 'reset';
    print "] $line\n";
    ProcessPacket($line);
}
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

# Don't change these unless you're adding dependencies to the list
package bot::pIRCbot;
our @EXPORT = qw($host $port $nickname $username $autojoin);
use Exporter qw(import);
use strict;
use warnings;

# Variables for server connection, change this to reflect your bot info
our $host = 'irc.serenia.net';
our $port = '6667';
our $nickname = 'pIRCbot';
our $username = 'pIRCbot';
our $autojoin = '';   # Leave blank for none


sub GotInvite
{
    my ($nick, $address, $channel) = @_;
    # We got an invite!
    # -
    # This is an example of how we would handle an invite or another event
    &::SocketSend("JOIN " . $channel);
    &::SocketSend("PRIVMSG " . $channel . " Hello $nick!");
}

sub GotJoin
{
    my ($nick, $address, $channel) = @_;
    # Someone (or we) joined
}

sub GotPart
{
    my ($nick, $address, $channel, $reason) = @_;
    # Someone (or we) left the channel
}

sub GotChannelMessage
{
    my ($nick, $address, $channel, $message) = @_;
    # We got a message in a channel!
}

sub GotPrivateMessage
{
    my ($nick, $address, $message) = @_;
    # We got a message in private!
}

sub GotQuit
{
    my ($nick, $address, $channel, $reason) = @_;
    # Someone quit
}

# Return true, do not change this
1;
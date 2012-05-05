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

package modules::easysubs;
use modules::cmodes;
our @EXPORT = qw(SendRaw SendMessage SendAction SendInvite SendJoin SendPart SendKick SendQuit SendNick ReloadBot CheckModes NickCount);
use Exporter qw(import);
use strict;
use warnings;

sub SendRaw
{
    my ($command) = @_;
    if (! $command) {return;}
    &::SocketSend($command);
}

sub SendMessage
{
    my ($target, $message) = @_;
    if (! $target or ! $message) {return;}
    &::SocketSend("PRIVMSG $target :$message");
}

sub SendAction
{
    my ($target, $action) = @_;
    if (! $target or ! $action) {return;}
    &::SocketSend("PRIVMSG $target :\001ACTION $action\001");
}

sub SendInvite
{
    my ($nick, $channel) = @_;
    if (! $nick or ! $channel) {return;}
    &::SocketSend("INVITE $nick $channel");
}

sub SendJoin
{
    my ($channel) = @_;
    if (! $channel) {return;}
    &::SocketSend("JOIN $channel");
}

sub SendPart
{
    my ($channel, $reason) = @_;
    if (! $channel) {return;}
    &::SocketSend("PART $channel :$reason");
}

sub SendKick
{
    my ($channel, $target, $reason) = @_;
    &::SocketSend("KICK $channel $target :$reason");
}

sub SendQuit
{
    my ($reason) = @_;
    &::SocketSend("QUIT :$reason");
    exit(0);
}

sub SendNick
{
    my ($nick) = @_;
    if (! $nick) {return;}
    &::SocketSend("NICK $nick");
}

sub ReloadBot
{
    &::ReloadBot;
}

sub CheckModes
{
    my ($channel, $nick) = @_;
    if (! $channel) {return;}
    if (! $nick){return $channels{lc($channel)}{'modes'};}
    return $channels{lc($channel)}{'nicks'}{lc($nick)};
}

sub NickCount
{
    my ($channel) = @_;
    if (! $channel) {return;}
    my $nickcount = 0;
    
    while (my ($key, $value) = each %{ $channels{lc($channel)}{'nicks'} } )
    {
        $nickcount++;
    }
    return $nickcount;
}

1;
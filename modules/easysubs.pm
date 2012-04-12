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
our @EXPORT = qw(SendRaw SendMessage SendAction SendInvite SendJoin SendPart SendKick SendQuit ReloadBot);
use Exporter qw(import);
use strict;
use warnings;

sub SendRaw
{
    my ($command) = @_;
    &::SocketSend($command);
}

sub SendMessage
{
    my ($target, $message) = @_;
    &::SocketSend("PRIVMSG $target :$message");
}

sub SendAction
{
    my ($target, $action) = @_;
    &::SocketSend("PRIVMSG $target :\001ACTION $action\001");
}

sub SendInvite
{
    my ($nick, $channel) = @_;
    &::SocketSend("INVITE $nick $channel");
}

sub SendJoin
{
    my ($channel) = @_;
    &::SocketSend("JOIN $channel");
}

sub SendPart
{
    my ($channel, $reason) = @_;
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

sub ReloadBot
{
    &::ReloadBot;
}

1;
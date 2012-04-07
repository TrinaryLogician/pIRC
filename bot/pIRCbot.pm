#!/usr/bin/perl
package bot::pIRCbot;
our @EXPORT = qw($host $port $nickname $username $maskhost $autojoin);
use Exporter qw(import);
use strict;
use warnings;

# -- Only add your bot code bellow this line unless you need a dependency

# Variables for server connection, change this to reflect your bot info
our $host = 'irc.serenia.net';
our $port = '6667';
our $nickname = 'pIRCbot';
our $username = 'pIRCbot';
our $maskhost = 0; # Whether or not to use umode +x, 1 = yes, 0 = no
our $autojoin = '';   # Leave blank for none

# We got an invite
sub GotInvite
{
    my ($nick, $address, $channel) = @_;
    # Automatically accept any invite to channels
    &::SocketSend("JOIN $channel");
}

# We got a message in a channel!
sub GotChannelMessage
{
    my ($nick, $address, $channel, $message) = @_;
    # Respond to anyone saying 'ping' with 'pong'
    if ($message eq 'ping')
    {
        &::SocketSend("PRIVMSG $channel pong");
    }
}

1; # Return true, do not change this
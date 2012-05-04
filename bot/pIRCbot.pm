#!/usr/bin/perl
package bot::pIRCbot;
use modules::easysubs;
use modules::logging;
our @EXPORT = qw($host $port $usessl $reconn $nickname $nickpass $username $usermode $autojoin);
use Exporter qw(import);
use strict;
use warnings;
# -- Only add your bot code bellow this line unless you need a dependency

# Variables for server connection, change this to reflect your bot info
our $host = 'ircs.lantea.org';
our $port = '9000';
our $usessl = 1;        # Use SSL (0 to disable)
our $reconn = 1;        # Reconnect after 5 seconds if disconnected (0 to disable)
our $nickname = 'Pierce';
our $nickpass = '';     # If the nick is register, use this for NickServ identify, blank for none
our $username = 'Pierce';
our $usermode = '';   # Usermode string, leave default if you don't understand
our $autojoin = '';     # Auto join a channel on connection, blank for none

# We got an invite
sub GotInvite
{
    my ($nick, $address, $channel) = @_;
    # Automatically accept any invite to channels (and log it)
    SendJoin($channel);
    LogMessage('bot', "Accepted invite from $nick to $channel");
}

# We got a message in a channel!
sub GotChannelMessage
{
    my ($nick, $address, $channel, $message) = @_;
    # Respond to anyone saying 'ping' with 'pong'
    if ($message eq 'ping')
    {
        SendMessage($channel, "pong");
    }
}

1; # Return true, do not change this

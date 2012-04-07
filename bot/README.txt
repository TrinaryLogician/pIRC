This file is for all information regarding how to properly use pIRCbot.pm
to make your own IRC bot. Use this as a reference, do not guess, and do not
make changes to pirc.pl unless you are SURE you know what you are doing.

--

To send data to the server you must use the SocketSend subroutine. To
access this, call &::SocketSend(), here is an example message to #test
&::SocketSend("PRIVMSG #test Hello everyone!");

For a list of commands to use, see the IRC Client RFC (RFC 2812).

--

"Events" are things happening on the server, like joins and messages. These
are passed to pIRCbot.pm along with a few already split up variables for easy
use. If you need one, add the sub and the variables, if you don't, either don't
add it, or remove it from the example pIRCbot.pm. Below is a list of currently
available events and the variables passed with them. These ARE case sensitive.

Here is an example of how an event should be added to your pIRCbot.pm:

sub GotChannelMessage
{
    my ($nick, $address, $channel, $message) = @_;
    # Code to handle event below here
}

What are these variables for?
$nick       - This is the nick of the person sending the command
$address    - This is the address of the person sending the command
$channel    - This is the channel that the event is in/for
$message    - This is the message for PrivateMessage or ChannelMessage
$reason     - This is the reason left when someone is kicked, parts, quits
$newnick    - This is used when someone changes their nick

GotJoin()           - This will fire happen when anyone joins a channel that
                      the bot is currently in, including the bot. Available
                      variables: $nick, $address, $channel
                      
GotChannelMessage() - This will fire happen when anyone sends a message in a
                      channel that the bot is currently in. Available
                      variables: $nick, $address, $channel, $message
                      
GotPrivateMessage() - This will fire happen when anyone sends a message to
                      the bot in private. Available variables: $nick,
                      $address, $message
                      
GotPart()           - This will fire when anyone leaves a channel that the
                      bot is currently in. Available variables: $nick,
                      $address, $channel, $reason
                      
GotInvite()         - This will fire when someone invites the bot to a
                      channel. Available variables: $nick, $address, $channel
                      
GotQuit()           - This will fire whenever someone (in a channel the bot
                      is also in) quits. Available variables: $nick,
                      $address, $channel, $reason
                      
GotKick()           - This will fire when someone gets kicked from a channel
                      the bot is in (including the bot). Available variables:
                      $nick, $address, $channel, $reason
                      
GotNick()           - This will fire when someone changes their nick in a
                      channel the bot is in (including the bot). Available
                      variables: $nick, $address, $newnick
                      
-- This file will be updated as I add more events or things that regard the
use of pIRCbot.pm
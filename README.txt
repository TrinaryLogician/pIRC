pIRC (Perl IRC) is a bot framework intended for those wishing to build an
IRC bot who either don't want to spend time building a whole client, or who
don't have a lot of knowledge and want a more simple way of making their bot.

--

When this project is completed anyone will be able to download pIRC and use
it simply by coding their bot inside the bot module, I intend to make this
as easy to use as possible, so even people very new to programming/scripting
can use it with ease. The main script will handle all connection and data
processing, it will pass relevent things to the bot module with the data
coming in already sorted and split up. For example, if someone was to send a
message in a channel, the bot module wouldn't see
"Somenick!~Someuser@somehost.com PRIVMSG #somechan :hello guys!"
This would instead be processed by the main script and then passed to the
bot module as a subroutine GotChannelMessage() with sorted variables
$nick, $address, $channel and $message

I also plan to have the main script handle a list of channels the bot is in
and their users, and modes for each. This will allow the bot module access
to check a users modes or a channels modes, to for example, only allow a
channel owner or channel op the ability to administer the bot.

-- I will probably do a fresh README soon --
This is my (TrinaryLogician's) fork of Bradical's pIRC framework. This is
basically for some tinkering and parallel development at the moment

I can be found at:
#lantea on irc.lantea.org (Bradical's network)

--

Support:
Bradley J Hammond
bradicaljh@hotmail.com (bugs, questions, suggestions)
#bradical on irc.mordor.io (anything really)

pIRC downloads: http://files.bradicaljh.com/pIRC/

If you're reading this file it means you have downloaded pIRC or are
looking at the source code for some reason on Github. pIRC is an IRC bot
framework coded in Perl, it is aimed at making the development of bots a
little easier by providing a script that will connect to the IRC network
given, maintain the connection, process the data and hand it to the bot
module in a more simple form. pIRC also has a module which makes SENDING
data easier, for more information on how to receive and send data, refer
to the bot manual located at bots/manual.txt

--

pIRC requires a number of things to operate, the obvious being Perl,
but it also requires the modules listed below to be installed:

- IO::Socket::IP

- IO::Socket::SSL

- Module::Reload::Selective

Once these are installed all you need to do to run pIRC is just that,
run ./pirc.pl and you're away. To run as a daemon use ./pirc.pl -d and
use ./pirc.pl -h to see other command line options.

As for making your bot, that's up to you, refer to the bot manual in the
bot directory and get coding!

--
This file was last updated on 15/04/2012
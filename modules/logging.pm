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

package modules::logging;
our @EXPORT = qw(LogMessage);
use Exporter qw(import);
use strict;
use warnings;
use Term::ANSIColor;
use POSIX;

sub LogMessage
{
    my ($type, $message) = @_;
    
    if (! $type or ! $message) {return;}
    
    if (lc($type) eq 'connection')
    {
        print color 'WHITE BOLD'; print strftime("[%H:%M:%S] ", localtime()); print color 'RESET';
        print color 'CYAN BOLD'; print '***'; print color 'RESET'; print ' ';
        print $message . "\n";
    }
    elsif (lc($type) eq 'send')
    {
        print color 'WHITE BOLD'; print strftime("[%H:%M:%S] ", localtime()); print color 'RESET';
        print color 'BLUE BOLD'; print '>>>'; print color 'RESET'; print ' ';
        print $message . "\n";
    }
    elsif (lc($type) eq 'receive')
    {
        print color 'WHITE BOLD'; print strftime("[%H:%M:%S] ", localtime()); print color 'RESET';
        print color 'RED BOLD'; print '<<<'; print color 'RESET'; print ' ';
        print $message . "\n";
    }
    elsif (lc($type) eq 'bot')
    {
        print color 'WHITE BOLD'; print strftime("[%H:%M:%S] ", localtime()); print color 'RESET';
        print color 'MAGENTA BOLD'; print '###'; print color 'RESET'; print ' ';
        print $message . "\n";
    }
    else
    {
        print color 'WHITE BOLD'; print strftime("[%H:%M:%S] ", localtime()); print color 'RESET';
        print color 'YELLOW BOLD'; print '---'; print color 'RESET'; print ' ';
        print $message . "\n";
    }
}

1;
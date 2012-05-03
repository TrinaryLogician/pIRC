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

package modules::cmodes;
use strict;
use warnings;
our @EXPORT = qw(%channels NewChan cMode uMode);
use Exporter qw(import);

our %channels = ( );

sub NewChan
{
    my ($channel) = @_;
    $channels{lc($channel)}{'modes' => '', 'nicks' => {}};
}

sub uMode
{
    my ($channel, $namestring) = @_;
    my @nicks = split(' ', $namestring);
    foreach(@nicks)
    {
        if ($_ =~ m/^\+/ or $_ =~ m/^\%/ or $_ =~ m/^\@/ or $_ =~ m/^\&/ or $_ =~ m/^\~/ or $_ =~ m/^\*/)
        {
            $_ =~ m/^(.)(.*)$/;
            $channels{lc($channel)}{'nicks'}{lc($2)} = $1;
        }
        else
        {
            $channels{lc($channel)}{'nicks'}{lc($_)} = '-';
        }
    }
}

sub cMode
{
    my ($channel, $modes, $params) = @_;
    $modes = $modes . " " . $params if $params;
    $channels{lc($channel)}{'modes'} = $modes;
}

1;
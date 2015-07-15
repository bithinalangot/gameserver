#!/usr/bin/perl
use IO::Socket;

# ********************************************************************
#
#  This program is free software; you can redistribute it and/or modify it 
#  under the terms of the GNU General Public License as published by the Free 
#  Software Foundation; either version 2 of the License, or (at your option) 
#  any later version.
#  
#  This program is distributed in the hope that it will be useful, but WITHOUT 
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for 
#  more details.
#  
#  You should have received a copy of the GNU General Public License along with
#  this program; if not, write to the Free Software Foundation, Inc., 59 
#  Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#  
#  The full GNU General Public License is included in this distribution in the
#  file called LICENSE.
#  
#  Contact Information:
#			Lexi Pimenidis, <lexi@i4.informatik.rwth-aachen.de>
#			RWTH Aachen, Informatik IV, Ahornstr. 55 - 52056 Aachen - Germany
#*******************************************************************************
# 
# CREATED AND DESIGNED BY 
#    Boris Leidner
#
#

##
##	Game server script for email service
##	Arguments: <COMMAND> <IP> <KEY> <FLAG>
##

# exit codes:
# 0 error, 1 ok, 2 system error
use constant ERR => 1;
use constant NO_FLAG => 5;
use constant OK => 0;
use constant SYS_ERR => 1;

use constant SMTP_PORT => 2525;
use constant POP3_PORT => 110;

sub store {
	my $sock = new IO::Socket::INET (PeerAddr => $_[0], PeerPort => SMTP_PORT, Proto => 'tcp');
	return ERR unless $sock;

	<$sock>;
	print $sock "helo localhost\n";
	<$sock>;
	print $sock "mail from: $_[1]\n";
	<$sock>;
	print $sock "rcpt to: $_[1]\n";
	<$sock>;
	print $sock "data\n";
	print $sock "$_[2]\n";
	print $sock ".\n";
	$answer=<$sock>;
	close($sock);
	if ($answer =~ /354/) {
		return OK;
	} else {
		return ERR;
	}
}

sub retrieve {
	my $sock = new IO::Socket::INET (PeerAddr => $_[0], PeerPort => POP3_PORT, Proto => 'tcp');
	return ERR unless $sock;

	<$sock>;
	print $sock "user $_[1]\n"; <$sock>;
	print $sock "pass $_[1]\n"; <$sock>;

	print $sock "retr 1\n";
	print $sock "quit\n";
	while (<$sock>) {
		$inp=$_;
		$answer = "$answer$inp";
		if ($inp eq ".\n") {
			last;
		}
	}
	close($sock);
	if ($answer =~ /$_[2]/) {
		return OK;
	} else {
		return NO_FLAG;
	}
}


if ($ARGV[0] eq "store") {
	exit &store($ARGV[1], $ARGV[2], $ARGV[3]);
} elsif ($ARGV[0] eq "retrieve") {
	exit &retrieve($ARGV[1], $ARGV[2], $ARGV[3]);
}

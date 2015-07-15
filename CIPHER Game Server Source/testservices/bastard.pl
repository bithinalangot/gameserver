#!/usr/bin/perl -w

use strict;

#*************** CREATE TREE OF PROCESSES
my $count = abs($ARGV[0]) || 0;
my $orig = 1;

do {
	if(fork()) {
		$count = 0;
	} else {
		$orig = 0;
		--$count;
	}
} while($count);

# RESIST!
print "i'm $$ - try and kill me!\n" if($orig);
foreach(keys %SIG) {
	print "$_ " if($orig);
	$SIG{$_} = 'IGNORE';
}
print "\n" if($orig);

# IDLE
sleep(60);

exit(0);

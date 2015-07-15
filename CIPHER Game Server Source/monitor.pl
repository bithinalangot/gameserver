#!/usr/bin/perl -w

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
#			Lexi Pimenidis, <i4@pimenidis.org>
#
#*******************************************************************************
# 
# CREATED AND DESIGNED BY 
#    Lexi Pimenidis, <i4@pimenidis.org>
#
#

use strict;

#***********************************************************************
#
#  Main Thread of the Game Server
#
# (Note: A former version of the game server trusted all data it received 
#        from the database! This was resolved, but maybe we missed something)
# (Note for me: read DBI::taint for more informations about this)
#
#***********************************************************************

use common;
use mysql;
common->init();

my $hostname = get_hostname();

#-------------------------------------------------------------- DRONES

sub check_drones {
	my @drones = mysql->query('SELECT id,UNIX_TIMESTAMP(heartbeat),host,pid,status FROM drone');

	unless(@drones) {
		mylog('there are currently no drones connected, according to the database',0,0,0,$log_warning);
		return;
	}
	#mylog('check drones...',0,0,0,$log_operation);

	my $stale_drone = time() - get_config(0,'stale_drone',120);

	foreach my $drone (@drones) {
		my ($did,$heartbeat,$drone_hostname,$pid,$status) = @$drone;
		# check if drone is still existing (only on this machine!)
		if ($drone_hostname eq $hostname) {
			if (kill(0,$pid)) {
				# TODO: check if process's name is corelating to 'drone.pl'?
			} else {
				mylog("drone $did, pid=$pid seems to be gone - removing from DB",0,0,0,$log_error);
				mysql->query('UPDATE service_status SET fi_drone=NULL WHERE fi_drone=?',$did);
				mysql->query('DELETE FROM drone WHERE id=?',$did);
			}
		}

		# check if drone is hanging
		if ($heartbeat < $stale_drone) {
			mylog("drone $did\@$drone_hostname, pid=$pid seems to be hanging",0,0,0,$log_warning);
		}

	}
}

# check if system seems to have too much or too less drones?
sub check_load {
	#	# simple counting of slots
	#	my $total_slots = mysql->single_value('SELECT count(*) FROM service_status');
	#	my $free_slots  = mysql->single_value('SELECT count(*) FROM service_status WHERE fi_drone IS NULL');
	#	mylog("LOAD: $free_slots out of $total_slots slots are free",0,0,0,$log_operation);
	#	if ($free_slots > 0 ) {
	#		# TODO: possible underload situation?
	#	} else {
	#		# TODO: possible overload situation?
	#	}
	# Better: check time of next event to be done
  my @slot = mysql->single_row('SELECT service_status.fi_game, service_status.fi_service, service_status.fi_team, service_status.ip,
                                       UNIX_TIMESTAMP(service_status.last_change)+`game_x_service`.flags_interval AS next 
                                FROM service_status,`game_x_service` 
                                WHERE (service_status.fi_drone IS NULL)AND(service_status.fi_service=`game_x_service`.fi_service) 
                                ORDER BY NEXT
                                LIMIT 1;');
  if (@slot) {
    # check delay of work
    my $future = $slot[4]-time();
		# OK, we're WAY ahead of time
    if ($future>=60) {
			mylog("LOAD: we're way too bloated - $future seconds until next event",0,0,0,$log_operation);
			return;
    };
    if ($future>=-2) {
			mylog("LOAD: we're fine - still $future seconds until next event",0,0,0,$log_verbose);
			return;
    };
		$future=abs($future);
    if ($future<=10) {
			mylog("LOAD: we're close - just $future seconds behind!",0,0,0,$log_warning);
			return;
    };
    if ($future<=30) {
			mylog("LOAD: we're getting late - already $future seconds behind!",0,0,0,$log_warning);
			return;
    };
		mylog("LOAD: SEVERE WARNING - we're $future seconds late!",0,0,0,$log_error);
	} else {
		mylog("LOAD: can't get data from service_status",0,0,0,$log_warning);
	}
}

# check if there are zombie-processes
my $ps_banner_once;

sub check_zombies_with_ps {
	my ($ps_bin) = @_;

	unless($ps_banner_once) {
		mylog("ZOMBIES: check for zombies with help of OS-tool '$ps_bin'",0,0,0,$log_operation);
		$ps_banner_once = 1;
	}

	# get list of processes
	unless(open(PS,"$ps_bin ux |")) {
		mylog("getting list of processes with '$ps_bin': $!",0,0,0,$log_error);
		return;
	}
	my @lines = <PS>;
	close(PS);
	if(scalar(@lines)<3) {
		mylog("strange result from $ps_bin: not enough lines (only ".scalar(@lines)." lines)",0,0,0,$log_warning); 
		return;
	}
	# parse header line
	my %name_to_col;
	my @header = split(/\s+/,$lines[0]);
	foreach(my $i=0;$i<@header;++$i) {
		$name_to_col{$header[$i]} = $i;
	}
	my $stat_column = $name_to_col{'STAT'};
	my $user_column = $name_to_col{'USER'};
	my $pid_column = $name_to_col{'PID'};
	my $cmd_column = $name_to_col{'COMMAND'};
	unless(defined $stat_column) {
		mylog("could not find column 'STAT' in header line '$lines[0]' from $ps_bin",0,0,0,$log_warning);
		return;
	}
	unless(defined $user_column) {
		mylog("could not find column 'USER' in header line '$lines[0]' from $ps_bin",0,0,0,$log_warning);
		return;
	}
	unless(defined $pid_column) {
		mylog("could not find column 'PID' in header line '$lines[0]' from $ps_bin",0,0,0,$log_warning);
		return;
	}
	unless(defined $cmd_column) {
		mylog("could not find column 'COMMAND' in header line '$lines[0]' from $ps_bin",0,0,0,$log_warning);
		return;
	}
	# parse output to find zombies
	foreach(@lines) {
		my @cols = split(/\s+/);
		if ($cols[$stat_column] eq 'Z') {
			# foud a zombie!
			my ($user,$pid) = ($cols[$user_column],$cols[$pid_column]);
			# make output
			splice(@cols,0,$cmd_column);
			my $cmd = join(' ',@cols);
			# check how we should react
			if (get_config(0,'kill_zombies',0)) {
				mylog("ZOMBIE: KILLING process $pid from $user = '$cmd'",0,0,0,$log_error);
				kill(-9,$pid);
			} else {
				mylog("ZOMBIE: process $pid from $user = '$cmd'",0,0,0,$log_error);
			}
		}
	}
}

my $ps_bin;
sub check_zombies {
	# TODO: check on zombies using /proc-filesystem
	if (-d '/proc') {
	}
	# check with the help of 'ps-binary'
	  # get ps-binary, if not already found
		unless($ps_bin) {
			$ps_bin=`which ps`;
			unless($ps_bin)  {
				mylog("can not find 'ps'-binary for zombie detection",0,0,0,$log_error);
				$ps_bin='IGNORE';
			} else {
				chomp($ps_bin);
			}
		}
	check_zombies_with_ps($ps_bin) if($ps_bin ne 'IGNORE');
}

#-------------------------------------------------------------- 

# exit handler: quit on Ctrl-C
my $quit = 0;
$SIG{INT} = sub { print "quitting..\n"; ++$quit; };
$SIG{HUP} = sub { common->read_config(); };

srand(time());

mylog("Monitor started",0,0,0,$log_critical);

my $clear = `clear`;

# -------------------------- main loop
while(! $quit) {
	# check drones
	check_drones();

	# check if system seems to have too much or too less drones?
	check_load();

	# check for zombie processes on the system
	check_zombies();

  # sleep
  sleep(1);
};
# terminate
mylog("Finishing Monitor...cleaning up",0,0,0,$log_critical);
common->done();

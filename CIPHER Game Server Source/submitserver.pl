#!/usr/bin/perl -w
#
#********************************************************************
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
#                       Lexi Pimenidis, <lexi@i4.informatik.rwth-aachen.de>
#                       RWTH Aachen, Informatik IV, Ahornstr. 55 - 52056 Aachen - Germany
#*******************************************************************************
# 
# CREATED AND DESIGNED BY 
#    Lexi Pimenidis, lexi@i4.informatik.rwth-aachen.de
#
#

use strict;
use IO::Socket;
use IO::Select;

$|=1;

use common;
use mysql;
common->init();

my $debug = 0;
my $port = 31337;
my $select_timeout = 10;
my $service_status_timeout = 10;
my $flag_resubmit_delay = 20;

my $game = $config_game;  #take from config

my $flag_length_in_characters = 2*get_config($game,'flag_len',16);
my $flag_regexp = qr/^\s*([0-9a-f]{$flag_length_in_characters})\s*$/i;

# ***************************************************************************

my $quit = 0;

sub int_handler {
	print "captured terminating signal: @_\n";
	$quit = 1;
}

sub warn_handler {
	my ($line) = @_;
	$line = '<DEFAULT>' unless($line);
	mylog("WARNING: $line",$game,0,0,$log_critical);
	die($line) if ($line =~ /server has gone away/);
}

$SIG{'__WARN__'} = &warn_handler;
#$SIG{'INT'} = $SIG{'TERM'} = &int_handler;

# used to sync time with the database server
# always returns time as from the DB-server
my $time_offset_to_db_host;
sub get_time {
  unless(defined $time_offset_to_db_host) {
    my $remote_time = mysql->single_value('SELECT unix_timestamp(now());');
    $time_offset_to_db_host = $remote_time - time();
    mylog("determined time offset of $time_offset_to_db_host seconds to DB-host",$config_game,0,0,$log_warning);
    return $remote_time;
  }
  return time() + $time_offset_to_db_host;
}

# ***************************************************************************

my %teams;                 # stores some data about teams participating in this game
my %flag_score;            # stores scores for flags in this game
my %submitted;             # stores, which teams have submitted which flag
my %flags;                 # stores static data about flags (id, team, expiry, service)
my %service_status;        # caches status of team's services

sub sendLine {
  my ($client,$message) = @_;
	chomp($message);
	print $message,"\n" if($debug);
	eval {
	  print $client $message,"\r\n";
	};
	warn_handler($@) if ($@);
}

sub state {
	my ($line) = @_;
	chomp($line);
	print $line,"\n";
}

sub is_service_up {
	my ($team,$service) = @_;

	my $id = "$team|$service";

	# check if status is cached, and return
	if (defined($service_status{$id})) {
		if (time < $service_status{$id}{'timeout'}) {
			return $service_status{$id}{'is_up'};
		}
	} else {
		$service_status{$id} = {};
	}
	# get fresh data from DB
	$service_status{$id}{'timeout'} = time + $service_status_timeout;
	my $status = mysql->single_value("SELECT status FROM service_status WHERE (fi_game=?)AND(fi_service=?)AND(fi_team=?)",$game,$service,$team);
	$status =0 unless(defined $status);

	return $service_status{$id}{'is_up'} = ($status == $script_successfull ? 1 : 0);
}

# ***************************************************************************

sub submit_flag {
	my ($stream,$team,$flag) = @_;
	
	# check if input is roughly similar to a flag
	if ($flag =~ $flag_regexp) {
		# refine data
		$flag = $1;
		# avoid multiple inputs from the same team
		my $allow_flag = 1;
		if (defined $submitted{$team}{$flag}) {
			if ($submitted{$team}{$flag} > time() ) {
				sendLine($stream,"Sorry, please dont resubmit flags too fast (keep $flag_resubmit_delay sec interval)");
				$allow_flag = 0;
			}
		};
	 	if ($allow_flag) {
			state("team $team is submitting $flag");
			$submitted{$team}{$flag} = time + $flag_resubmit_delay;

			# fetch static data of this flag either from database or from memory
			if (!(defined $flags{$flag})) {
				my @ownerQ = mysql->single_row(	'SELECT id,fi_team,UNIX_TIMESTAMP(valid_expires),fi_service '.
																				'FROM `flag` WHERE (fi_game=?)and(flag=?)',$game,$flag);
				# is the flag existing?
				if (!$ownerQ[0]) {
					sendLine($stream,'Sorry, flag not in database');
					return 1 unless($debug);
				};
				$flags{$flag} = {};
				$flags{$flag}{'id'} = ($ownerQ[0] || 0);
				$flags{$flag}{'team'} = ($ownerQ[1] || 0);
				$flags{$flag}{'expires'} = ($ownerQ[2] || 0);
				$flags{$flag}{'service'} = ($ownerQ[3] || 0);
			};
			my $flag_id      = $flags{$flag}{'id'};
			my $flag_team    = $flags{$flag}{'team'};
			my $flag_expires = $flags{$flag}{'expires'};
			my $flag_service = $flags{$flag}{'service'};
			
			# is the team the owner of the flag?
			if ($team == $flag_team) {
				sendLine($stream,'Sorry, flag is your own');
				return 1 unless($debug);
			};
			
			# is flag still valid?
			if ($flag_expires < get_time() ) {
				sendLine($stream,'Sorry, flag expired');
				return 1 unless($debug);
			};

			# check service
			if (!(defined $flag_score{$flag_service})) {
				sendLine($stream,'Sorry, internal error #1');
				return 1 unless($debug);
				$flag_score{$flag_service} = 1;  # for debugging purposes only
			};

			# stop, if team has the same service NOT FUNCTIONAL
			unless(is_service_up($team,$flag_service)) {
				sendLine($stream,'Sorry, your team does not have the corresponding service up');
				return 1;
			}

			# stop, if flag was already submited by this team (should only be relevant, if submit-server was restarted)
			my $time1st = mysql->single_value('SELECT time FROM scores WHERE (fi_game=?)and(fi_flag=?)and(fi_team=?)',$game,$flag_id,$team);
			if ( defined $time1st ) {
				sendLine($stream,'Sorry, you already submitted this flag');
				return 1;
			};

			# captured a flag!
			sendLine($stream,'Congratulations, you captured a flag!');
			
			# make the following code thread-safe
			mysql->query('LOCK TABLES scores WRITE, event WRITE');
			
				# remove defensive points
				mysql->query('DELETE FROM scores WHERE (fi_game=?)and(fi_team=?)and(fi_flag=?)and(multiplier=0)',$game,$flag_team,$flag_id);
			
				# insert new offensive points
				score($game,$flag_service,$team,$flag_id,$flag_score{$flag_service},1,
							"Captured Flag $flag (id $flag_id) from team $flag_team 's service $flag_service");
			
			# release lock
			mysql->query('UNLOCK TABLES');

		};
	} else {
		# special commands?
		return 0 if ($flag =~ /^\s*quit\s*$/i);
		return 0 if ($flag =~ /^\s*exit\s*$/i);
		# nothing matches
		sendLine($stream,'Sorry, is this a flag?');
	};
	return 1;
}

# ***************************************************************************

mylog('WARNING: submit-server running in DEBUG-mode!',$game,0,0,$log_critical) if ($debug);

# drop privileges
#$< = 65534;
#$( = 65534;
#$> = 65534;
#$) = 65534;

# check general stats about game
my @game_row = mysql->single_row('SELECT id,UNIX_TIMESTAMP(start),UNIX_TIMESTAMP(stop) FROM game WHERE id=?',$game);
my ($gg,$game_start,$game_stop) = @game_row;
if (!(defined $gg && ($gg == $game))) { 
	mysql->done();
	die("there's no game $game\n");
};

# preload TEAMS
my @rows_teams = mysql->query('SELECT team.id,team.name FROM `game_x_team`,team '.
                              'WHERE (`game_x_team`.fi_team=team.id)and(fi_game=?)',$game);
foreach my $row_team (@rows_teams) {
	# store team's name
	$teams{ @{$row_team}[0] } = @{$row_team}[1];
	# store list of flags submitted by a team
	$submitted{ @{$row_team}[0] } = {};
}

#preload scores
my @rows_scores = mysql->query('SELECT fi_service,score_offensive FROM `game_x_service` '.
  	                           'WHERE (fi_game=?)',$game);
foreach my $row_score (@rows_scores) {
	$flag_score{ @{$row_score}[0] } = @{$row_score}[1];
};

# main loop: accepts connections and starts sessions
my $server = IO::Socket::INET->new(
	LocalPort => $port,
  Type => SOCK_STREAM,
  Reuse => 1,
  Listen => 25 )
  or die "Couldn't open server on port $port";
my $select = IO::Select->new($server);

state("listening on port $port");

my %sessions;
my $last_conns = 0;
my $conn_display = time();

while(!$quit) {
	if(my @fds = $select->can_read(0.1)) {
		foreach my $socket (@fds) {
			# ----------- NEW CONNECTION
			if ($socket == $server) {
				my $client = $socket->accept();
				if ( (get_time()>=$game_start) && (get_time()<=$game_stop) ) {
					# handle request, if game is currently running
					$sessions{$client} = {};
					$sessions{$client}{'timeout'} = time() + $select_timeout;
					$sessions{$client}{'team'} = 'unknown';
					$sessions{$client}{'fd'} = $client;
					sendLine($client,'Please identify your team with its numerical team-number');
					$select->add($client);
				} else {
					# give a nice error message
					if ( get_time()<$game_start)  {
						sendLine($client,'Sorry, game not started');
					} else {
						sendLine($client,'Sorry, game over');
					};
					close($client);
				};
			} else {
				# --------------- ESTABLISHED CONNECTION
				my $input = <$socket>;
				my $keep = 0;
				if ($input) {
					# if session is in 'authorization' state, the team ID needs to be entered
					if ($sessions{$socket}{'team'} eq 'unknown') {
						my $team = intval($input);
						if ($team && defined $teams{$team}) {
							sendLine($socket,"Welcome '$teams{$team}'. Enter one flag per line, or QUIT when finished");
							$sessions{$socket}{'team'} = $team;
							$keep = 1;
						} else {
							sendLine($socket,"Sorry, don't recognize your team");
						}
					} else {
						$keep = submit_flag($socket,$sessions{$socket}{'team'},$input);
					}
				} else {
					state("terminated session for team ".$sessions{$socket}{'team'});
				}
				if($keep) {
					# set new timeout
					$sessions{$socket}{'timeout'} = time() + $select_timeout;
				} else {
					# remove connection
					$select->remove($socket);
					delete $sessions{$socket};
					close($socket);
				}
			}
		}
	}
	# statistics: display active connections
	my @conns = keys %sessions;
	my $now = time();
	if ((scalar(@conns) != $last_conns)&&($conn_display != $now)) {
		$last_conns = scalar(@conns);
		state("now handling $last_conns streams");
		$conn_display = $now;
	}
	# check if any old connections timed out
	foreach my $conn (@conns) {
		if ($sessions{$conn}{'timeout'} < $now) {
			sendLine($sessions{$conn}{'fd'},'Timeout!');
			$select->remove($sessions{$conn}{'fd'});
			close($sessions{$conn}{'fd'});
			delete $sessions{$conn};
		}
	}
	# check if game is over
	if (get_time() > $game_stop ) {
		state('Game is over - closing down');
		foreach my $conn (keys %sessions) {
			sendLine($sessions{$conn}{'fd'},'Sorry, game over');
			$select->remove($sessions{$conn}{'fd'});
			close($sessions{$conn}{'fd'});
			delete $sessions{$conn};
		}
		$quit = 1;
	};
}
state("closing down");
close($server);

exit 0;


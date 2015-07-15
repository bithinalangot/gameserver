#!/usr/bin/perl -w

use strict;
use IO::Socket;
use IO::Select;

use common;
common->init();

my $submit_host = '127.0.0.1';
my $submit_port = 31337;
my $timeout = 2;

# read config and game-id from ARGUMENTS
( @ARGV >= 2 ) || die('give CONFIG_FILE, GAME, [optional: RELOAD-DELAY] as parameters');

my $configfile = $ARGV[0];
my $game= intval($ARGV[1]);
my $reload = 2;
if(defined $ARGV[2]) {
	$reload = 1.0*$ARGV[2];
}

use mysql;
mysql->init($db_host,$db_name,$db_user,$db_pass);

my $game_name = mysql->single_value("SELECT name FROM game WHERE id=?",$game);
if (!(defined $game_name)) { 
	print "there's no name for the game $game\n"; 
	mysql->done(); 
	exit 1;
};

my $quit = 0;
$SIG{HUP} = sub { ++$quit; };

# preload TEAMS
my %teams;
my @rows_teams = mysql->query('SELECT team.id,team.name FROM `game_x_team`,team '.
                              'WHERE (`game_x_team`.fi_team=team.id)and(fi_game=?)',$game);
foreach my $row_team (@rows_teams) {
	# store team's name
	$teams{ @{$row_team}[0] } = @{$row_team}[1];
}
my @team_keys = keys(%teams);

# MAIN LOOP
while(!$quit) {
	# choose a random team
	my $team = @team_keys[rand()*(scalar @team_keys)];
	# choose a random flag from another team
	# flag should not be expired yet
	my $big_rand = rand()*10000;
	my $random_flag = mysql->single_value("SELECT flag FROM `flag` ".
        		                            "WHERE (valid_expires>now())AND(fi_game=?)AND(fi_team!=?) ".
																				"ORDER BY sin(id*$big_rand) ".
																				"LIMIT 1",$game,$team);
	if (defined($random_flag) && (length($random_flag)>0) ) {
		# submit flag
		if (my $sock=new IO::Socket::INET(PeerAddr=>$submit_host,PeerPort=>$submit_port,Proto=>'tcp',)) {
			eval {
				SUBMIT: {
					# login: wait for banner, enter numerical team-ID
					my $line;
					my $sel = IO::Select->new($sock);
					last SUBMIT unless($sel->can_read($timeout));
					$sock->sysread($line,1024);
					$sock->send("$team\n");
					# wait for announcement to submit flags, submit flag
					last SUBMIT unless($sel->can_read($timeout));
					$sock->sysread($line,1024);
					print "submitting $random_flag\n";
					$sock->send("$random_flag\n");
					# wait for result of submitted flag and display
					last SUBMIT unless($sel->can_read($timeout));
					$sock->sysread($line,1024);
					print $line;
					# leave
					$sock->send("quit\n");
					print "ready\n";
				}
			};
			if($@) {
				warn("$@");
			  sleep(1);	
			}
			close($sock);
		} else {
			print "can't connect to submit server\n"
		}
	} else {
		print "currently no flag for team $team ($teams{$team}) to submit..\n";
	}
	sleep($reload);
}

mysql->done();


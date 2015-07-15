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
#      Lexi Pimenidis, <i4@pimenidis.org>
#
#*******************************************************************************
# 
# CREATED AND DESIGNED BY 
#    Lexi Pimenidis, <i4@pimenidis.org>
#
#


use strict;

use IPC::Open3;                    # \_ used for polling status of scripts
use POSIX ":sys_wait_h";           # /

use IO::Select;
use IO::Socket;

use Time::HiRes qw(usleep);

use common;
use mysql;
common->init;
die('need to define a game in configuration file!') unless($config_game);

# exit handler: quit on Ctrl-C
my $quit=0;
$SIG{'TERM'} = $SIG{'INT'} = sub { 
  mylog("caught INT",0,0,0,$log_critical);
  ++$quit; 
};
$SIG{'HUP'} = sub { common->read_config(); };

$|=1;

#***********************************************************************
#
#  Main Thread of the Game Server
#
# (Note: A former version of the game server trusted all data it received 
#        from the database! This was resolved, but maybe we missed something)
# (Note for me: read DBI::taint for more informations about this)
#
#***********************************************************************

my $drone_id;

sub connect_to_db {
  my $hostname = get_hostname();
  # store to database that this process is there
  # -> $$ is perl variable for process ID
  $drone_id = mysql->query('INSERT INTO drone VALUES(NULL,now(),?,?,NULL)',$hostname,$$);
}

sub disconnect_from_db {
  # remove locks 
  mysql->query('UPDATE service_status SET fi_drone=NULL WHERE fi_drone=?',$drone_id);
  # remove this process from list of active drones in DB
  mysql->query('DELETE FROM drone WHERE id=?',$drone_id);
}

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

sub set_drone_status {
  my ($line) = @_;
  $line='' unless($line);
  chomp($line);
  #mylog($line,0,0,0,$log_verbose);  # TODO: be more specific with $game, $service, $team
  mysql->query('UPDATE drone SET status=?,heartbeat=NOW() WHERE id=?',$line,$drone_id);
}

# make sure that no record is create more than once
sub create_service_status {
  my ($game,$service,$team,$ip) = @_;
  my $foo = mysql->single_value('SELECT fi_game FROM service_status WHERE fi_game=? AND fi_service=? AND fi_team=?',$game,$service,$team);
  return if($foo);
  mysql->query('INSERT INTO service_status VALUES(?,?,?,NULL,NULL,?,NULL,now(),NULL,NULL)',$game,$service,$team,$ip);
}

# tests, if all necessary tables are filled
# - fill service_status with all games, services and teams
sub check_db {
  mylog('check db... start',0,0,0,$log_operation);
  mysql->query('LOCK TABLE service_status WRITE, game READ, `game_x_service` READ, `game_x_team` READ ');
  # check all games, which have started, or start within one day, and that have not stopped
  #my @games = mysql->query("SELECT id FROM game WHERE (start<=date_add(now(),interval '1' day))and(stop>=NOW())");
  #foreach my $game_rec (@games) { 
    #my $game = $$game_rec[0];
    my $game = $config_game;
    my @services = mysql->query("SELECT fi_service,server_ip FROM `game_x_service` WHERE (fi_game=?)",$game);
    mylog("no services",$game,0,0,$log_warning) unless @services;
    my @teams = mysql->query("SELECT fi_team,server_ip FROM `game_x_team` WHERE (fi_game=?)",$game);
    mylog("no teams",$game,0,0,$log_warning) unless @teams;
    foreach my $service (@services) {
      if ($$service[1]) {
        # service is only provided on a single machine, not once per team
        create_service_status($game,$$service[0],undef,$$service[1]);
      } else {
        foreach my $team (@teams) {
          # service is only provided a once per team
          create_service_status($game,$$service[0],$$team[0],$$team[1]);
        };
      };
    };
    #}
  mysql->query('UNLOCK TABLES');
  mylog('check db... stop',0,0,0,$log_operation);
}

# checks DB for work to do, returns work or undef
# 'work' is a list of (game,servce,team,ip,timestamp)
my ($game_start,$game_stop,$where_services);
sub get_service_to_work_on {
  # step 0 - check if game is actually running
  unless($game_start || $game_stop) {
    my @running = mysql->single_row("SELECT unix_timestamp(start),unix_timestamp(stop) FROM game WHERE (id=?)",$config_game);
    $game_start = $running[0];
    $game_stop  = $running[1];
    die("insufficient data about game $config_game in database: start and stop are missing") unless($game_start && $game_stop);
  }
  my $now = get_time();
  return undef if ($now<$game_start);
  return undef if ($now>$game_stop);
  # step 1 - check if some stale records exist
  my @stale = mysql->query('SELECT fi_game,fi_service,fi_team FROM service_status WHERE fi_drone=?',$drone_id);
  if (@stale) {
    foreach my $row (@stale) {
      mylog("stale record for this drone ($drone_id)",$$row[0],$$row[1],$$row[2],$log_critical);
    }
    mysql->query('UPDATE service_status SET fi_drone=NULL WHERE fi_drone=?',$drone_id);
  }
  # step 2 - check for free slot
  #   to this end get a list of all possible work to be done and order by 
  #    'timestamp of last work'+'interval of next work'
  if((! defined $where_services) && ($config_services)) {
    $where_services = "AND(";
    my $or='';
    foreach(split(/,/,$config_services)) {
      $where_services .= "$or(service_status.fi_service=$_)";
      $or = 'OR';
      mylog("this drone ($drone_id) will work on service $_",$config_game,0,0,$log_critical);
    }
    $where_services .= ")";
  } else {
    $where_services='';
  }
  mysql->query('LOCK TABLE service_status WRITE, `game_x_service` READ');
  my @slot = mysql->single_row("SELECT service_status.fi_game, 
                                       service_status.fi_service, 
                                       service_status.fi_team, 
                                       service_status.ip,
                                       UNIX_TIMESTAMP(service_status.last_change)+`game_x_service`.flags_interval AS next 
                                FROM service_status,`game_x_service` 
                                WHERE (service_status.fi_drone IS NULL)AND
                                      (service_status.fi_service=`game_x_service`.fi_service)AND
                                      (service_status.fi_game=?) $where_services
                                ORDER BY NEXT
                                LIMIT 1;",$config_game);
  if (@slot) {
    # check if something is to do
    my $future = $slot[4]-$now;
    if ($future>0) {
      # no, nothing
      mysql->query('UNLOCK TABLES');
      return undef;
    }
    # found something to do
    mylog("choose to work on this service (ip=$slot[3], time=$future)", $slot[0],$slot[1],$slot[2], $log_operation);
    mysql->query('UPDATE service_status SET fi_drone=?,last_change=NOW() WHERE fi_game=? AND fi_service=? AND fi_team=?',$drone_id,$slot[0],$slot[1],$slot[2]);
  }
  mysql->query('UNLOCK TABLES');
  return @slot;
}

# if work is done, return lock on work
my %store_output_scripts;
sub release_lock {
  my ($game,$service,$team,$seconds,$result) = @_;
  mylog("stopped to work on this service", $game,$service,$team, $log_operation);
  mysql->query('LOCK TABLE service_status WRITE');
  mysql->query('UPDATE service_status SET fi_drone=NULL,last_change=NOW() WHERE fi_game=? AND fi_service=? AND fi_team=?',$game,$service,$team);
  mysql->query('UNLOCK TABLES');
  # implement performance table, where stats on performance is saved (optional)
  if (get_config($game,'store_performance',0)) {
    unless(%store_output_scripts) {
      mysql->query('INSERT INTO performance VALUES(?,?,?,now(),?,?,NULL,NULL,NULL,NULL)',$game,$service,$team,$seconds,$result);
      $store_output_scripts{'store_public'} = undef;
      $store_output_scripts{'store_internal'} = undef;
      $store_output_scripts{'retrieve_public'} = undef;
      $store_output_scripts{'retrieve_internal'} = undef;
    } else {
      mysql->query('INSERT INTO performance VALUES(?,?,?,now(),?,?,?,?,?,?)',$game,$service,$team,$seconds,$result,
                      $store_output_scripts{'store_public'},$store_output_scripts{'store_internal'},
                      $store_output_scripts{'retrieve_public'},$store_output_scripts{'retrieve_internal'});
    }
  } else {
    undef %store_output_scripts;
  }
}

# -------------------------- main work


# used to get all data pending on a FD, coming from a child process
sub get_all_from_fd {
  my ($fd,$stop_local_time) = @_;
  my $buffer='';
  my $sel = new IO::Select($fd);
  GET_IO: while(my @fds = $sel->can_read(0.1)) {
    foreach my $fd (@fds) {
      unless(sysread($fd,$buffer,0x10000,length($buffer))) {
        $sel->remove($fd);
      }
    }
    last GET_IO if(time()>$stop_local_time);
  }
  return $buffer;
}

# store all process ids of processes which could not have been immediatly terminated
# in this stucture and try to kill later on
# (foreach pid the local time ies stored, when the pid was actually stored in this hash)
my %hanging_processes;

# this function kills stuff 'later' - or at least tries to call 'waitpid' in order to remove zombies
sub handle_hanging_processes {
  my @pids = keys %hanging_processes;
  foreach my $pid (@pids) {
    # repeat sending deadly signals
    kill(-9,$pid);
    # try to collect process
    my $status = waitpid($pid,WNOHANG || WUNTRACED);
    if ($status) {
      my $delta = time() - $hanging_processes{$pid};
      # mylog("finished off zombie after $delta seconds");
      delete $hanging_processes{$pid};
    }
  }
}

# buffer '$cwd' to avoid calling `pwd` more than once
my $cwd;

# execute a script to set or retrieve a flag. the script is terminated after $script_delay 
# in the worst case. the return code is ensured to be a value from 0 to 3.
sub external_script {
  my ($cmd,$action,$ip,$flag_db_id,$flag_id,$flag, $game,$service,$team) = @_;

  unless(-x $cmd) {
    return (3,"can't find $cmd, or not executable\n");
  }

  # determine CWD, if not found, yet
  unless($cwd) {
    $cwd = `pwd`;
    chomp($cwd);
  }
  mylog('problem determining current working directory',$game,$service,$team,$log_error) unless($cwd);
  # split $cmd in path and exectuable
  my ($path,$executable)=('.',$cmd);
  if ($cwd && ($cmd =~ /^(.+\/)(.+)$/)) {
    if(0) { #-d $1) {
      $path = $1;
      $executable = $2;
    } else {
      mylog("'$1', as the path part of '$cmd', is not a directory?",$game,$service,$team,$log_error) unless($cwd);
    }
  } else {
    mylog('problem determining directory of executable',$game,$service,$team,$log_error) unless($cwd);
  }
  

  # execute script
  my $delay = get_config($game,'script_delay',15);
  my $end_time_local = time() + $delay;
  mylog("executing in $path '$executable $action $ip $flag_id $flag'",$game,$service,$team,$log_verbose);
  my $pid = open3(\*CHLD_IN, \*CHLD_OUT, \*CHLD_ERR, "$executable",$action,$ip,$flag_id,$flag,$team,$flag_db_id);
  mylog("running on pid $pid with delay $delay",$game,$service,$team,$log_verbose);
  # kid is running in the background. wait for it to finish
  my ($kid,$ret)  = (0,$script_error);
  do {
    $kid = waitpid($pid,WNOHANG || WUNTRACED);
    usleep(50000) unless($kid);
  } until (($kid>0)||(time() > $end_time_local)||$quit);
  # try to read all of the output that was produced by the kid
  my $stdout = get_all_from_fd(\*CHLD_OUT,$end_time_local+1);;
  my $stderr = get_all_from_fd(\*CHLD_ERR,$end_time_local+2);;
  # close file handles to kid
  close \*CHLD_IN;
  close \*CHLD_OUT;
  close \*CHLD_ERR;
  # kid finished, or time is up
  if ($kid) {
    # script terminated correctly and in time
    $ret = $? >>8;
  } else {
    # script didn't terminate in time
    mylog("need to kill script $cmd",$game,$service,$team,$log_warning);
    # Zombie problem -> handled in monitor.pl
    if (kill(-9, $pid)){
      $kid = waitpid($pid, 0);
      $ret = $script_timeout;
    } else {
      # now we're into serious trouble.. remember to poll PID later
      $hanging_processes{$pid} = time();
      # return and check for status later
      mylog("could not kill script $cmd with PID $pid",$game,$service,$team,$log_error);
      $ret = $script_error;
    };
  };

  mylog("return code of '$executable $action $ip $flag_id $flag' as $ret",$game,$service,$team,$log_verbose);

  return ($ret,$stdout,$stderr);
}

sub init_random {
  # FIXME: check if Math::TrulyRandom is available and use it
  # get some entropy from OS
  my $buffer='';
  open(RND,'< /dev/urandom') || die("there is no source for entropy (/dev/urandom): $!");
  binmode(RND);
  read(RND,$buffer,16);
  close(RND);
  # put entropy into random number generator
  my $foo = unpack("J*",$buffer);
  srand($foo);
}

sub generate_flag {
  my ($game) = @_;
  # FIXME: use Math::Random, if available
  
  my $flag_id_len = get_config($game,'flag_id_len',8);
  my $flag_length = get_config($game,'flag_len',16);

  # create random flag-id. this is necessary to avoid players guessing the flag-id!
  my $flag_id = '';
  for(my $i=0; $i<$flag_id_len ; ++$i ) {
    $flag_id .= sprintf("%02x",int(rand(256)));
  };
  # create flag
  my $flag = '';
  for(my $i=0; $i<$flag_length ; ++$i ) {
    $flag .= sprintf("%02x",int(rand(256)));
  };
  return ($flag_id,$flag);
}

sub set_new_flag {
  my ($game,$team,$service,  $interval,$interval_expires,$cmd_store,$ip) = @_;

  # process flag INTERNALLY
    # generate flag  ($flag_id,$flag_from,$flag_to,$flag);
    my ($flag_id,$flag) = generate_flag($game);
    # save flag to DB
    my ($id) = mysql->query("INSERT INTO `flag` ".
                 "VALUES(NULL,?,?,?,NOW(),ADDDATE(now(),INTERVAL ? SECOND),ADDDATE(now(),INTERVAL ? SECOND),?,?);",
                 $game,$service,$team,$interval,$interval_expires,$flag_id,$flag);
    # save flag in status
    mysql->query("UPDATE service_status SET fi_flag=? WHERE (fi_game=?)and(fi_service=?)and(fi_team=?)",
                 $id,$game,$service,$team);
    # ready to place flag
    mylog("Generated new flag $id: $flag with id $flag_id",$game,$service,$team,$log_verbose);
  
  # communicate flag to OUTSIDE
    my ($ret,$stdout,$stderr) = external_script($cmd_store,'store',$ip,$id,$flag_id,$flag,$game,$service,$team);
    # store information for gamemasters
    if (%store_output_scripts) {
     $store_output_scripts{'store_public'} = $stdout;
     $store_output_scripts{'store_internal'} = $stderr;
   }
    # store return code
    mylog("$stdout\n$stderr",$game,$service,$team,$log_verbose);
    return;
};

# this function does the actual check, if the stored flag is still there and valid
sub evaluate_flag {
  my ($game,$team,$service,  $flag_db_id,$flag_id,$flag,$cmd_ret,$ip, $score_uptime,$score_defensive) = @_;
  mylog("evaluate flag $flag",$game,$service,$team,$log_verbose);

  # check if flag was submitted by some other team in the meantime
  # this would mean that the flag has been captured and thus the flag can not be used to
  # actively get defensive scores
  my $flag_submitted = mysql->single_value("SELECT count(fi_team) as nr FROM scores WHERE (fi_flag=?)and(fi_team!=?)and(multiplier>0)",$flag_db_id,$team);
  # execute script and check flag status anyway in order to allow other team debugging
  my ($ret,$stdout,$stderr) = external_script($cmd_ret,'retrieve',$ip,$flag_db_id,$flag_id,$flag,$game,$service,$team);
  # store informational info for players
  mysql->query('UPDATE service_status SET info=?,debug=? WHERE (fi_game=?)AND(fi_service=?)AND(fi_team=?)',$stdout,$stderr,$game,$service,$team);
  # store information for gamemasters
  if (%store_output_scripts) {
    $store_output_scripts{'retrieve_public'} = $stdout;
    $store_output_scripts{'retrieve_internal'} = $stderr;
  }
  # evaluate status
  unless($flag_submitted) {
    # if flag was not submitted in the meantime, and returned successfully
    if ($ret == $script_successfull) {
      mylog("$stdout\n$stderr",$game,$service,$team,$log_verbose);
      score($game,$service,$team,$flag_db_id, $score_uptime + $score_defensive,0,"defending service $service");
      return $ret;
    }
    # if flag was not submitted in the meantime, but not returned successfully
    if ($ret == $script_wrong_flag) {
      mylog("$stdout\n$stderr",$game,$service,$team,$log_verbose);
      score($game,$service,$team,$flag_db_id, $score_uptime,0,"holding up service $service");
      return $ret;
    }
  }
  mylog("script '$cmd_ret' returned with code $ret",$game,$service,$team,$log_warning);
  return $ret;
};

# this function checks if there is a flag to be checked for this
# partciular combination of game/team/service. this is the case, if
# there is actually a flag stored on the service and enough time has passed
#
# if ther service had no flag at all, or the old flag has been checked, a new flag is placed
sub do_work_on_service {
  my ($game,$team,$ip,$service) = @_;
  my $place_new_flag=1;
  my $return_code;

  set_drone_status("working on game $game, service $service, team $team, ip $ip");  
  # get data of the service from DB
  my @serviceQ  = mysql->single_row("SELECT store,retrieve,flags_interval,flags_expire,score_defensive,score_uptime ".
                                    " FROM `game_x_service` WHERE (fi_game=?)and(fi_service=?)",$game,$service);
  my ($cmd_store,$cmd_ret,$interval,$interval_expires,$score_defensive,$score_uptime) = @serviceQ;

  set_drone_status("getting last flag");
  # get last flag, as of table "service_status"
  my ($stat_flag,$last_status,$last_change)= mysql->single_row("SELECT fi_flag,status,UNIX_TIMESTAMP(last_change) 
                                                                FROM service_status 
                                                                WHERE (fi_game=?)and(fi_service=?)and(fi_team=?)",$game,$service,$team);
  EVAL_FLAG: if (defined($stat_flag)) { 
    # check if foul was done and timeout has not been exceeded
    if (defined $last_status && ($last_status == $script_foul_timeout)) {
      if ( get_time() <= $last_change + get_config($game,'foul_timeout',300) ) {
        mylog("service $service is still in FOUL-timeout",$game,$service,$team,$log_warning);
        last EVAL_FLAG;
      }
    }
    # get FLAG data of LAST(!) FLAG
    my ($flag_id,$flag,$flag_to) = mysql->single_row("SELECT flag_id,flag,UNIX_TIMESTAMP(valid_until) FROM `flag` WHERE id=?",$stat_flag);
    if ($flag_id && $flag) {
      # check age of flag to determine whether action shall take place
      if ( $flag_to < get_time() ) {
        # check if flag can be retrieved
        if (defined $cmd_ret && -x "$cmd_ret") {
          set_drone_status("evaluate flag");
          $return_code = evaluate_flag($game,$team,$service,  $stat_flag,$flag_id,$flag,$cmd_ret,$ip, $score_uptime,$score_defensive);
        } else {
          mylog("service $service has no executable to retrieve a flag, or '$cmd_ret' is not executable",$game,$service,$team,$log_warning);
          $return_code = $script_error;
        }
        # set new status to DB
        mysql->query("UPDATE service_status SET status=? WHERE (fi_game=?)and(fi_service=?)and(fi_team=?)",$return_code,$game,$service,$team);
      } else {
        # there is a valid flag, so don't place a new one
        $place_new_flag = 0;
      }
    } else {
      mylog("no flag $stat_flag in table `flag`",$game,$service,$team,$log_error);
    }
  }
  
  # set new FLAG
  if ($place_new_flag) {
    if (defined $cmd_store && -x "$cmd_store") {
      set_drone_status("set new flag");
      set_new_flag($game,$team,$service,  $interval,$interval_expires,$cmd_store,$ip);
    } else {
      mylog("service $service has no executable to store a new flag, or '$cmd_store' is not executable",$game,$service,$team,,$log_warning);
    }
  }

  set_drone_status('finished');
  return $return_code;
};


init_random();
mylog("Drone started",0,0,0,$log_critical);
connect_to_db();
check_db();

# -------------------------- main loop
while(! $quit) {
  # fetch a task
  my ($game,$service,$team,$ip) = get_service_to_work_on();
  if (defined $game && defined $team && defined $ip && defined $service) {
    # do task
    my $measure_duration_start = time();
    my $result = do_work_on_service($game,$team,$ip,$service);
    release_lock($game,$service,$team,time()-$measure_duration_start,$result);
  } else {
    # idle
    set_drone_status('idle');
    sleep(1);
  }
  # check for hanging processes
  handle_hanging_processes();
};
# terminate
mylog("Terminating drone ...cleaning up",0,0,0,$log_critical);
disconnect_from_db();
common->done();

# vim: et ts=2

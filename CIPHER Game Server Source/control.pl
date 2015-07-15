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

use common;
use mysql;
common->init;

my $max_hostname_len = 20;

sub usage {
  print "usage: $0 <config-file> [-h|-?] [-l] [-n] [-d X]
  -l    = list drones
  -n    = new drone
  -d X  = stop drone X
";
  exit(0);
}

# **************************************** functions

sub list_drones {
  my $db_max_hostname_len = mysql->single_value('select max(length(host)) from drone');
  if (defined $db_max_hostname_len && ($db_max_hostname_len < $max_hostname_len)) {
    $max_hostname_len = $db_max_hostname_len;
  }

  my @drones = mysql->query('SELECT id,UNIX_TIMESTAMP(heartbeat),host,pid,status FROM drone ORDER BY id');

  print "ID      PID ".(' 'x$max_hostname_len)." HEARTBEAT   ACTION\n";
  foreach my $drone (@drones) {
    my ($id,$heartbeat,$host,$pid,$status) = @$drone;
    printf("#%02d - %5d@%-".$max_hostname_len."s - %3d sec - %s\n",$id,$pid,substr($host,0,$max_hostname_len),time()-$heartbeat,$status);
  }
}

sub new_drone {
  mylog("fire up new drone",0,0,0,$log_critical);
  # check if screen is there
  my $screen= `which screen`;
  chomp($screen);
  if ($screen) {
    # get random screen-id
    my $screen_id = 'drone-';
    for(my $i=0;$i<8;++$i) {
      $screen_id .=sprintf("%02x",int(rand(256))) 
    }
    # fire up drone
    system("screen -S $screen_id -d -m ./drone.pl");
    return 1;
  } else {
    mylog("no `screen' found - FIXME!",0,0,0,$log_error);
    return 0;
  }
}

sub kill_drone {
  my ($id) = @_;
  mylog("killing drone $id",0,0,0,$log_critical);
  my ($pid,$host) = mysql->single_row('SELECT pid,host FROM drone WHERE id=?',$id);
  unless($pid) {
    mylog("no drone $id in database",0,0,0,$log_error);
    return 0;
  }
  unless($host eq get_hostname()) {
    mylog("drone $id runs on different host: $host",0,0,0,$log_error);
    return 0;
  }
  # start to kill slightly
  mylog("sending TERM to $pid",0,0,0,$log_operation);
  kill('TERM',$pid);
  my $stop_time = time() + 10;
  while( time() < $stop_time) {
    sleep(1);
    return 1 unless(kill(0,$pid));
  }
  # ok, now kill REALLY
  mylog("sending KILL to $pid",0,0,0,$log_warning);
  kill('KILL',$pid);
  $stop_time = time() + 10;
  while( time() < $stop_time) {
    sleep(1);
    return 1 unless(kill(0,$pid));
  }
  mylog("could not kill $pid :(",0,0,0,$log_error);
  return 0;
}

# **************************************** MAIN

PARSE: while(my $arg = shift @ARGV) {
  usage() if ($arg eq '-h'); 
  usage() if ($arg eq '-?'); 
  if ($arg eq '-l') {
    list_drones();
  }
  if ($arg eq '-n') {
    if(new_drone()) {
      sleep(1);
      list_drones();
    }
  }
  if ($arg eq '-d') {
    my $id = shift @ARGV;
    usage() unless($id =~ /^\d+$/);
    if(kill_drone($id)) {
      sleep(1);
      list_drones();
    }
  }
}

common->done();
# vim: et

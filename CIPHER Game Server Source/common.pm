package common;
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


# This package shall provide easy access to a configuration file

use strict;
use DBI;
use mysql;

BEGIN{
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 0.1;
  @ISA = qw(Exporter);
  @EXPORT    = qw(&score &intval 
                  &mylog $log_critical $log_error $log_warning $log_operation $log_verbose 
                  $db_host $db_name $db_user $db_pass $config_game $config_services
                  $script_successfull $script_error $script_wrong_flag $script_output_garbled $script_network 
                             $script_timeout $script_foul_timeout
                  &get_config &get_hostname
                  );
  @EXPORT_OK = @EXPORT;
}

our ($db_host,$db_name,$db_user,$db_pass);
our $config_game;
our $config_services;

our $log_critical  = 0;
our $log_error     = 1;
our $log_warning   = 2;
our $log_operation = 3;
our $log_verbose   = 4;
my $default_debug  = $log_operation;

# return codes of gameserver scripts
#
# | 7 6 5 4 3 2 1 0 | 7 6 5 4 3 2 1 0 |
#                                 | |
#                                 | +- bit0 = 0 == everything OK (also: all bits set to 0)
#                                 |         = 1 == error
#                                 +- bit1 = 0 == interpret higher bits as single error code
#                                         = 1 == interpret higher bits as bit set for multiple errors
#  (we currently only support bit1=0)  
our $script_successfull      = 0;
our $script_error            = 1;
our $script_wrong_flag       = (1<<2) | $script_error;   # "5"  give team at least 'uptime'-scores
our $script_output_garbled   = (2<<2) | $script_error;   # "9"
our $script_network          = (3<<2) | $script_error;   # "13" 
our $script_timeout          = (4<<2) | $script_error;   # "17" should only be set by gameserver itself, if script was killed
our $script_foul_timeout     = (5<<2) | $script_error;   # "21" 

my %config;

sub cmdline {
  my $config_file = 'config';
  # check f default config file is present
  unless(-s $config_file) {
    ( @ARGV >= 1 ) || die("give configuration file as parameter");
    $config_file = shift @ARGV;
    die("configuration file '$config_file' (1st parameter) doesn't exist") unless(-c $config_file);
  }

  open CONFIG, "< $config_file" || die("can't open configuration file $config_file");
  while(<CONFIG>) {
    # remove comments
    s/^\s*#.*//;
    # parse line
    PARSE: {
      if (/^\s*dbhost\s+(\S+)/) { $db_host=$1; last PARSE; };
      if (/^\s*dbname\s+(\S+)/) { $db_name=$1; last PARSE; };
      if (/^\s*dbuser\s+(\S+)/) { $db_user=$1; last PARSE; };
      if (/^\s*dbpass\s+(\S+)/) { $db_pass=$1; last PARSE; };
      if (/^\s*game\s+(\d+)/)   { $config_game=$1; last PARSE; };
      if (/^\s*services\s+([\d\s,]+)/)   { $config_services=$1; last PARSE; };
      if (/^\s*(\S+)/) { die("unkown option '$1' in configuration file") };
    };
  };
  close CONFIG;
};

sub init {
  cmdline();
  $db_host || die("no database-host given in configuration file");
  $db_name || die("no database-name given in configuration file");
  $db_user || die("no database-user given in configuration file");
  $db_pass || die("no database-password given in configuration file");
  mysql->init($db_host,$db_name,$db_user,$db_pass);
  mysql->my_connect();
  read_config();
};

sub get_config {
  my ($game,$name,$default) = @_;
  $name=lc($name);
  return $config{$game}{$name} if(defined $config{$game}{$name});
  return $config{0}{$name}     if(defined $config{0}{$name});
  return $default;
}

sub read_config {
  undef %config;
  mylog('reading config',0,0,0,$log_operation);
  my @rows = mysql->query('SELECT fi_game,name,value FROM `config`');
  foreach my $row (@rows) {
    my ($game,$name,$value) = @$row;
    $game=0 unless($game); # handle NULLs
    $config{$game}{lc($name)} = $value;
  }
}

sub done {
  mysql->done();
};

# ------------------------------ global functionality

sub get_hostname {
  my $hostname = `hostname`;
  $hostname =~ s/\s//sg;
  return $hostname if (length($hostname));
  die("can't return hostname");
}

sub mylog {
  my ($msg,$game,$service,$team,$importance) = @_;

  chomp($msg);

  if ($importance<=get_config($game,'debug',$default_debug)) {
    # print to console
    my $now = localtime();
    printf("%s - %d/%d/%d - %s\n",$now,$game,$service,$team,$msg);
    # make sure that values in DB are NULL instead of 0 because of referential integrity
    $game=undef unless($game);
    $service=undef unless($service);
    $team=undef unless($team);
    # store result, return identifier
    return mysql->query("INSERT INTO event VALUES(NULL,?,?,?,NOW(),?,?)",$game,$service,$team,$importance,$msg);
  };
  return 0;
}

sub score {
  my ($game,$service,$team,$flag,$scores,$multiplier,$reason) = @_;
  my $event = mylog("$scores points for $reason",$game,$service,$team,$log_operation);
  mysql->query("INSERT INTO scores values(?,?,?,?,?,?,now(),?)",$game,$service,$flag,$team,$event,$multiplier,$scores);
};


sub intval {
  my ($val) = @_;

  return 0 unless(defined $val);

  $val =~ s/\D//g;
  if ($val eq '') { $val = 0; };

  return $val;
};


1;
# vim: et ts=2

package mysql;
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

# This package shall provide easy access to a mysql db 
#

use strict;
use DBI;

BEGIN{
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 0.1;
  @ISA = qw(Exporter);
  @EXPORT    = qw();
  @EXPORT_OK = @EXPORT;
}

my $debug = 0;

my ($db_host,$db_name,$db_user,$db_pass);
my $dbh;

sub init {
  my $self = shift;
  ($db_host,$db_name,$db_user,$db_pass) = @_;
}

sub done {
  $dbh->disconnect();
}

sub my_connect {
  my $self = shift;
  # connect to database
  while(!$dbh) {
    $dbh = DBI->connect("DBI:mysql:database=$db_name:host=$db_host", $db_user, $db_pass);
    # TODO: a better solution is needed for error handling
    unless($dbh) {
       warn("Can't connect to database");
      sleep(2);
    }
  }
}


sub query {
  my $self = shift;
  my $line = shift;

  my_connect() unless ($dbh);

  # preprocessing: check if table-lock is needed
  my $table_lock;
  if ($line =~ /^INSERT INTO `?(event|flag|drone)`?/i) {
    $table_lock = $1;
    $dbh->do("LOCK TABLE `$table_lock` WRITE");
  }

  # prepare and execute
  my $q = $dbh->prepare($line);
  return undef unless($q);
  $q->execute(@_);

  # **************** post processing
  my $prefix = uc(substr($line,0,3));

  # for SELECT queries, return all data
  if($prefix eq 'SEL') {
    my $foo = $q->fetchall_arrayref();
    $q->finish();

    return @$foo;
  }
  # do nothing for update, delete, lock and unlock
  return undef if($prefix eq 'UPD');
  return undef if($prefix eq 'DEL');
  return undef if($prefix eq 'LOC');
  return undef if($prefix eq 'UNL');

   # if query was a INSERT return the id of the entry
  if ($table_lock) {
    $q= $dbh->prepare("SELECT max(id) FROM `$table_lock`");
    $q->execute();
    my ($id) = $q->fetchrow_array();
    $q->finish();

    $dbh->do('UNLOCK TABLES');
    return $id;
  }
  return undef;
}

# select query that should only return a single row
#
# somehow does a returned undef not work for arrays. so test for
# value with 
#     if ($result[0]) { RETURNED VALUES } else { NO ROW RETURNED };
sub single_row {
  my $self = shift;
  my $line = shift;

  my_connect() unless ($dbh);

  my $q = $dbh->prepare($line);
  return undef unless($q);
  $q->execute(@_);
  my $foo = $q->fetchrow_arrayref();
  $q->finish();

	return undef unless($foo);
  return @$foo;
}

# select query that should only return a single value
sub single_value {
  my $self = shift;
  my $line = shift;

  my_connect() unless ($dbh);

  my $q = $dbh->prepare($line);
  return undef unless($q);
  $q->execute(@_);
  my $foo = $q->fetchrow_arrayref();
  $q->finish();

  return $$foo[0];
}

1;

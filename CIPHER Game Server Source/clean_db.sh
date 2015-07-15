#!/bin/bash

# a small tool to clean up the database in between test runs

WHERE=""
if test "$1" ; then
	WHERE=" WHERE fi_game=$1"
fi

mysql -u root ctf <<EOF
DELETE FROM advisory $WHERE;
DELETE FROM event $WHERE;
DELETE FROM flag $WHERE;
DELETE FROM service_status $WHERE;
DELETE FROM scores $WHERE;
EOF


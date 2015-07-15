#!/bin/bash

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
#    Lexi Pimenidis, lexi@i4.informatik.rwth-aachen.de
#
#
# this script is called with the parameters
# "store/retrieve" "$IP" "$ID" "$flagge"

if [ $# -lt 4 ] ; then
        echo "script called with too less parameters"
        exit 1
fi

TIMEOUT=2
PORT=31337
NETCAT=/usr/bin/netcat
#NETCAT=/bin/nc

PASSWORDFILE=/data/gameserver/scripts/PASSWORD
PASSWORD=`egrep -e "^sfind $2 " $PASSWORDFILE | cut -f 4 -d ' '`
echo "password for ip $2 is $PASSWORD"

# PARAMETERS: file_for_result password keyword filename
function create_query {
        ENV=`perl -e '@environ = qw/FSI=. EXTN1= TST=xxx PASSWORD= EGG=/;print $environ[rand(@environ)];'`
        ID=$((RANDOM % 256))
        echo -e "id $ID\nuser whatever \npassword $2\nfilename $4\nkeyword $3\nenviron $ENV" > $1
}

if [ "$1" == "store" ] ; then
        QUERY=`mktemp`
        RETURN=1
        create_query $QUERY $PASSWORD $4 '*.c'

        if cat $QUERY | ssh $2 "$NETCAT -u -w $TIMEOUT localhost $PORT " ; then
                RETURN=0
        fi

        rm -f $QUERY
        exit $RETURN
elif [ "$1" == "retrieve" ] ; then
        QUERY1=`mktemp`
        QUERY2=`mktemp`
        RESULT=`mktemp`
        KEYWORD1=`perl -e '@keywords = qw/fork init tell test hello abc xxx microsoft/;print $keywords[rand(@keywords)];'`
        KEYWORD2=`perl -e '@keywords = qw/fork init tell test hello abc xxx microsoft/;print $keywords[rand(@keywords)];'`
        RANDOMPASS=`perl -e '@p=qw/password abcdef susie fritz iwan/;print $p[rand(@p)]'`
        create_query $QUERY1 $RANDOMPASS $KEYWORD1 '*.h'
        create_query $QUERY2 $PASSWORD   $KEYWORD2 '*.h'

        RETURN=1
        # check global availability
        if cat $QUERY1 |nc -w $TIMEOUT -u $2 $PORT | tee $RESULT ; then
                if test -s $RESULT ; then
                        # check local availability
                        if cat $QUERY2 |ssh $2 "$NETCAT -u -w $TIMEOUT localhost $PORT" | tee $RESULT ; then
                                if grep -q $4 $RESULT ; then
                                        RETURN=0
                                fi
                        fi
                fi
        fi

        rm -f $RESULT $QUERY1 $QUERY2
        exit $RETURN
else
        echo "didn't recognize parameter 1"
        exit 1
fi

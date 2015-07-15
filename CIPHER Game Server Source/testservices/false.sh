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

# receive parameters:
# $1 (store|receive)
# $2 IP
# $3 ID
# $4 Flagge
#
# Returns:
# 0: remote malfunction, service not up, answer garbled, other remote failures
# 1: service up, no flag  (not used for 'store')
# 2: success
# 3: internal error/local failure

if [ $# -lt 4 ] ; then
	echo "script called with too less parameters"
	exit 1
fi

if [ "$1" == "store" ] ; then
	# return always failure
 	exit 1
elif [ "$1" == "retrieve" ] ; then
	# return always failure
	exit 1
else
	echo "script called with unknown operation"
  exit 1
fi



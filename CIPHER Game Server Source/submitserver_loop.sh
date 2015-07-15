#!/bin/bash

while true ; do
  DATE=`date`
  LOAD=`uptime`
  echo "$DATE restarting , $LOAD" >> LOG.submitserver
  timeout -9 180 ./submitserver.pl config 3
  sleep 1
done


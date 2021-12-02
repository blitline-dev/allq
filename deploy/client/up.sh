#!/bin/bash

# Multiprocess allows us to kill the allq_client inside a container without exiting

if [ $MULTIPROCESS == "true" ]
then
  echo "Multi Process"
  /usr/bin/allq_client &
  while true
  do
   sleep 15
   ./healthcheck.sh
  done
else
  echo "Single Process"
  /usr/bin/allq_client
fi
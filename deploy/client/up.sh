#!/bin/bash

# Multiprocess allows us to kill the allq_client inside a container without exiting

if [ $MULTIPROCESS == "true" ]
then
  echo "Multi Process"
  /usr/bin/allq_client &
  while true
  do
   ./healthcheck.sh
   sleep 5
  done
else
  echo "Single Process"
  /usr/bin/allq_client
fi
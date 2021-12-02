#!/bin/bash

./stats.sh

retVal=$?
if [ $retVal -ne 0 ]; then
  echo "Trying to kill allq_client"
  pkill -x allq_client
  /usr/bin/allq_client &
  sleep 1
fi

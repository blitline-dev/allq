#!/bin/bash

retVal=$(./http_stat.sh)
if [ $retVal -ne 0 ]; then
  echo "Trying to kill allq_client http_stat"
  pkill -x allq_client
  /usr/bin/allq_client &
  sleep 1
  exit 0
fi

./stats.sh
retVal=$?
if [ $retVal -ne 0 ]; then
  echo "Trying to kill allq_client stats"
  pkill -x allq_client
  /usr/bin/allq_client &
  sleep 1
fi

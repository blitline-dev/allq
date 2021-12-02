#!/bin/bash

PORT="${STATS_HTTP_PORT:-8090}"
TIMEOUT="${SERVER_TIMEOUT:-10}"

curl -m $TIMEOUT http://localhost:$PORT/stats

retVal=$?
echo $retVal

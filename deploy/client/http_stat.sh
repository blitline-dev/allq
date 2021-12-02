#!/bin/bash

PORT="${STATS_HTTP_PORT:-8090}"
curl -m 5 http://localhost:$PORT

retVal=$?
echo $retVal

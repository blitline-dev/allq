#!/bin/bash

PORT="${STATS_PORT:-7768}"
TIMEOUT="${SERVER_TIMEOUT:-10}"

echo '{"action" : "stats", "params" : {}}' | socat -t $TIMEOUT -T $TIMEOUT - tcp4-connect:localhost:$PORT > /dev/null


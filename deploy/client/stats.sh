#!/bin/bash

PORT="${STATS_PORT:-7768}"
echo '{"action" : "stats", "params" : {}}' | socat -t 5 -T 5 - tcp4-connect:localhost:$PORT


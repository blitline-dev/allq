if [ "x$SERVER_IP" == "x" ]; then echo "No SERVER_IP set using localhost"; fi
if [ "x$SERVER_PORT" == "x" ]; then echo "No SERVER_PORT set using 7788"; fi

export ALLQ_DEBUG=true
export USE_SWEEPER=true
export HTTP_SERVER_PORT=8091
export TCP_CLIENT_PORT=7722
crystal src/all_q/client/client.cr

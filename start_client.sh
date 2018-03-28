if [ "x$SERVER_IP" == "x" ]; then echo "No SERVER_IP set using localhost"; fi
if [ "x$SERVER_PORT" == "x" ]; then echo "No SERVER_PORT set using 7788"; fi
crystal src/all_q/client/client.cr

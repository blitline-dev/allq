if [ "x$SERVER_IP" == "x" ]; then echo "No SERVER_IP set using localhost"; fi
if [ "x$SERVER_PORT" == "x" ]; then echo "No SERVER_PORT set using 7788"; fi

#export SERVER_STRING=3.93.57.206:7788
#export A_CURVE_PUBLICKEY="RTohRGcwR1YqcX0vKitdWDEwY21de0tIdi5xRDA2KzdORiVqJEVAVwA="
#export A_CURVE_SECRETKEY="YWFta0g0cS9XXUZVK1ZjMSRZSTFtTU5vPV5jWSkmQWJJVCZleG1KKwA="
#export A_CURVE_SERVER_PUBLICKEY="OnhdJHI9QlNKKTJRJUZXfTk5PTBnSklxW3BWXS5QbWVYWC5XW0hjdgA="

export ALLQ_DEBUG=true
export USE_SWEEPER=true
export HTTP_SERVER_PORT=8091
export TCP_CLIENT_PORT=7722
crystal src/all_q/client/client.cr

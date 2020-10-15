if [ "x$SERVER_IP" == "x" ]; then echo "No SERVER_IP set using localhost"; fi
if [ "x$SERVER_PORT" == "x" ]; then echo "No SERVER_PORT set using 7788"; fi

export SERVER_STRING=3.88.240.120:7788,54.156.34.209:7788
export A_CURVE_PUBLICKEY=PV4mOCFMN1YqQkg+SytCTzdheD9vPz93N3pLfVV4MzxzNF5aJnhsdwA=
export A_CURVE_SECRETKEY=cUVzQU1xOXY6N2dsMzRQR1ApNVkodmt7Un1hJVpLQTd9QVRjJTZEKwA=
export A_CURVE_SERVER_PUBLICKEY=bmElYUctdGZvPFVEYTZFbSElZmhVVTNlcUohTy5hMDpkdmVzcUBzIQA=

export ALLQ_DEBUG=true
export USE_SWEEPER=true
export HTTP_SERVER_PORT=8091
crystal src/all_q/client/client.cr

#!/bin/bash

echo "Attempting to run CLI"

echo "A_CURVE_PUBLICKEY=$A_CURVE_PUBLICKEY"
echo "A_CURVE_SECRETKEY=$A_CURVE_SECRETKEY"
echo "A_CURVE_SERVER_PUBLICKEY=$A_CURVE_SERVER_PUBLICKEY"
echo "SERVER_STRING=$SERVER_STRING"
echo "TCP_CLIENT_PORT=$TCP_CLIENT_PORT"
echo "ALLQ_DEBUG=$ALLQ_DEBUG"

cd allq_cli
/opt/rubies/ruby-2.5.3/bin/ruby main.rb



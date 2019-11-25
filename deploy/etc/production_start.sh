docker rm -f etcd_listener
sudo docker run --name=etcd_listener \
   -e "WATCH_PATH='/production/web/allq_servers_us'" \
   -e "ACTION_NAME=update_servers" \
   -e "PARAM_NAME=servers" \
   -e "SOCKET_LOCATION=/tmp/allq_client.sock" \
   etcd_listener


docker rm -f etcd_listener
sudo docker run --name=etcd_listener \
   -e "ETCD_SERVERS=https://portal2707-4.legendary-etcd-50.535566738.composedb.com:30180,https://portal1299-32.legendary-etcd-50.535566738.composedb.com:30180" \
   -e "ETCD_USER=root" \
   -e "ETCD_PASSWORD=MFTVCHKHROFZXZCG" \
   -e "ETCD_WATCH_PATH=/production/web/allq_servers_us" \
   -e "ACTION_NAME=update_servers"
   -e "PARAM_NAME=servers"
   etcd_listener


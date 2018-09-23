require 'etcdv3'
servers = ENV["ETCD_SERVERS"]
user = ENV["ETCD_USER"]
password = ENV["ETCD_PASSWORD"]
watch_tag = ENV["ETCD_WATCH_PATH"]
action_name = ENV["ACTION_NAME"]
# Secure connection with Auth
conn = Etcdv3.new(endpoints: servers, user: user, password: password)


event_count = 0
conn.watch(watch_tag) do |events|
    events.each do |event|
        puts event.kv.value
    end
    STDOUT.flush
    event_count = event_count + 1
    break if event_count >= 10
end


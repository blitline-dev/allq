require 'etcdv3'
require 'json'
require 'socket'

servers = ENV.fetch("ETCD_SERVERS")
user = ENV.fetch("ETCD_USER")
password = ENV.fetch("ETCD_PASSWORD")
watch_tag = ENV.fetch("ETCD_WATCH_PATH")
socket_location = ENV.fetch("SOCKET_LOCATION")

@action_name = ENV.fetch("ACTION_NAME")
@param_name = ENV.fetch("PARAM_NAME")

# Secure connection with Auth
conn = Etcdv3.new(endpoints: servers, user: user, password: password)

def build_json(value)
    v = {
        action: @action_name,
        params: {
        }
    }
    v[:params][@param_name.to_sym] = value
    return v.to_json
end

def send_to_socket(socket_location, data)
    s = UNIXSocket.new(socket_location)
    socket = UNIXSocket.new(socket_location)
    socket.write("#{data}\n")    
    socket.close
end

conn.watch(watch_tag) do |events|
    events.each do |event|
        begin
            v = event.kv.value
            if event.type.to_s == "PUT"
                json = build_json(v)
                puts json
                STDOUT.flush
                send_to_socket(socket_location, json)
            end
        rescue => ex
            puts ex.message
            STDOUT.flush
        end
    end
end


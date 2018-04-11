require "zeromq"
require "json"
require "uri"
require "./*"
require "./server_connection"

module AllQ
  class Client
    CLIENT_PORT = ENV["TCP_CLIENT_PORT"]? || "7766"

    def initialize(servers : Array(String))
      @server_connections = Hash(String, ServerConnection).new

      servers.each do |server|
        server_uri = server.split(":")
        server_path = server_uri[0].to_s
        port = server_uri[1].to_s
        new_server_connection = ServerConnection.new(server_path.to_s, port.to_s)
        @server_connections[new_server_connection.id] = new_server_connection
      end
      start_local_proxy(self)
    end

    def special_cased(parsed_data) : Nil | String
      results = nil
      if parsed_data["action"]?
        if parsed_data["action"].to_s == "stats"
          results = aggregate_stats(parsed_data)
        end
      end
      results
    end

    def aggregate_stats(parsed_data) : String
      result_hash = Hash(String, JSON::Any).new
      @server_connections.values.each do |server_client|
        output = server_client.send_string(parsed_data)
        result_hash[server_client.id] = JSON.parse(output)
      end
      result_hash.to_json
    end

    def send(data : String)
      hash = AllQ::Parser.parse(data)
      special_result = special_cased(hash)
      if special_result
        return special_result
      end
      if hash["q_server"]?
        q_server = hash.delete("q_server")
        server_client = @server_connections[q_server.to_s]
      else
        server_client = @server_connections.values.sample
      end
      q_server = server_client.id
      server_client.send_string(hash)
    end

    def start_local_proxy(raw_server)
      spawn do
        port = ENV["CL_PORT"]? || CLIENT_PORT
        listen = ENV["CL_LISTEN"]? || "0.0.0.0"
        debug = ENV["CL_DEBUG"]?.to_s == "true"
        allq_dir = "/tmp"

        server = Tcp.new(listen, port.to_i, allq_dir, true, raw_server)
        server.listen
      end
    end
  end
end

server_string = ENV["SERVER_STRING"]? || "127.0.0.1:5555"

client = AllQ::Client.new([server_string])
puts "version= #{ENV["version"]?}"
loop do
  sleep(1000)
end

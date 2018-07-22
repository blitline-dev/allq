require "zeromq"
require "json"
require "uri"
require "./*"
require "./handlers/*"
require "./server_connection"

module AllQ
  class Client
    CLIENT_PORT        = ENV["TCP_CLIENT_PORT"]? || "7766"
    JOB_ID_DIVIDER     = ","
    ALL_SERVER_ACTIONS = ["clear"]

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
          stats_aggregator = AllQ::StatsAggregator.new(@server_connections)
          results = stats_aggregator.process(parsed_data)
        end
        if parsed_data["action"].to_s == "peek"
          client_peek_handler = AllQ::ClientPeekHandler.new(@server_connections)
          results = client_peek_handler.process(parsed_data)
        end
        if parsed_data["action"].to_s == "ping"
          client_ping_handler = AllQ::PingAggregator.new(@server_connections)
          results = client_ping_handler.process(parsed_data)
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

    def get_job_id(hash) : Nil | JSON::Any
      job_id = nil
      if hash["params"]?
        params = hash["params"]
        if params["job_id"]?
          job_id = params["job_id"]
        elsif params["parent_id"]?
          job_id = params["parent_id"]
        end
      end
      return job_id
    end

    def send_all(str)
      @server_connections.values.each do |server_client|
        server_client.send_string(str)
      end
    end

    def send(data : String)
      hash = AllQ::Parser.parse(data)
      special_result = special_cased(hash)
      forced_connection = false
      if special_result
        return special_result
      end
      hash_action_name = hash["action"]?
      server_client = @server_connections.values.sample

      # ------------------------------------------------------------
      # The server connection handles appending server ID to
      # response. Job id has ServerID prepended to it for the
      # client app to keep. When that ID is sent back through
      # this client, it's pulled out and removed by server_connection
      # See method ServerConnection.send_string
      # -------------------------------------------------------------
      if hash_action_name
        job_id = get_job_id(hash)
        if job_id
          vals = job_id.to_s.split(JOB_ID_DIVIDER)
          size = vals.size
          if size == 2
            q_server = vals[0]
            job_id = vals[1]
            server_client = @server_connections[q_server]
            forced_connection = true
          elsif size == 1
            job_id = vals[0]
            puts "JobID isn't q_server FORMAT ->#{hash["action"]} ->#{job_id}"
          else
            raise "Illegal Job ID #{hash.to_s}"
          end
        end
      end

      begin
        if hash_action_name && ALL_SERVER_ACTIONS.includes?(hash_action_name)
          send_all(hash)
          return "{}"
        else
          server_client.send_string(hash)
        end
      rescue ex
        puts "Failed to send to server '#{hash_action_name}'"
        puts ex.inspect_with_backtrace

        progressive_backoff(hash, forced_connection, server_client)
      end
    end

    def progressive_backoff(hash, forced_connection, server_client)
      1.upto(3) do |i|
        puts "Retrying send..."
        if forced_connection
          val = wrapped_send(server_client, hash)
          return val unless val.nil?
        else
          @server_connections.values.each do |server_client|
            if server_client.ping?
              val = wrapped_send(server_client, hash)
              return val unless val.nil?
            end
          end
        end
        sleep(i)
      end
      raise "Faild send to server"
    end

    def wrapped_send(server_client, hash)
      begin
        return server_client.send_string(hash)
      rescue
      end
      return nil
    end

    def start_local_proxy(raw_server)
      spawn do
        port = ENV["CL_PORT"]? || CLIENT_PORT
        listen = ENV["CL_LISTEN"]? || "0.0.0.0"
        debug = ENV["CL_DEBUG"]?.to_s == "true"

        server = Tcp.new(listen, port.to_i, debug, raw_server)
        server.listen
      end
    end
  end
end

server_string = ENV["SERVER_STRING"]? || "127.0.0.1:5555"

client = AllQ::Client.new(server_string.split(","))
puts "version= #{ENV["version"]?}"

loop do
  sleep(10)
end

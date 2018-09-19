module AllQ
  class ServerConnectionCache
    SWEEP_DURATION = ENV["SWEEP_DURATION"]? || "10"
    STATS_STRING = "{\"action\":\"stats\",\"params\":{}}"
    STATS_HASH = JSON.parse(STATS_STRING)

    def initialize(servers : Array(String))
      @debug = false # INFER TYPE
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
      @sweeping = false
      @sweep_duration = 10
      @sweep_duration = SWEEP_DURATION.to_i
      @server_connections = Hash(String, ServerConnection).new
      @draining_connection_ids = Array(String).new
      servers.each do |server|
        server_uri = server.split(":")
        server_path = server_uri[0].to_s
        port = server_uri[1].to_s
        new_server_connection = ServerConnection.new(server_path.to_s, port.to_s)
        wait_for_ready(new_server_connection)
        @server_connections[new_server_connection.id] = new_server_connection
      end
    end

    def drain(server_id : String)
      # Handles both URL and ID based server lookup
      if server_id.includes?(":")
        @server_connections.values.each do |server_connection|
          url = server_id.split(":")[0]
          port = server_id.split(":")[1]
          if server_connection.server == url && server_connection.port.to_s == port.to_s
            @draining_connection_ids << server_connection.id
            return
          end
        end
      else
        server = @server_connections[server_id]
        @draining_connection_ids << server_id if server_id
      end
    end

    def add_server(server : String)
      server_uri = server.split(":")
      server_path = server_uri[0].to_s
      port = server_uri[1].to_s
      new_server_connection = ServerConnection.new(server_path.to_s, port.to_s)
      wait_for_ready(new_server_connection)
      @server_connections[new_server_connection.id] = new_server_connection
      puts "Added #{server}"
    end

    def wait_for_ready(new_server_connection)
      while !new_server_connection.ready?
        sleep(0.1)
      end
    end

    def restart_connection(id)
      bad_server_connection = @server_connections[id]
      server = bad_server_connection.server
      port = bad_server_connection.port
      @server_connections[id].close
      new_server_connection = ServerConnection.new(server, port)
      wait_for_ready(new_server_connection)
      new_server_connection.id = id
      @server_connections[new_server_connection.id] = new_server_connection
      puts "New Ping = #{new_server_connection.ping?}"

      return @server_connections[new_server_connection.id]
    end

    def start_sweeping
      return if @sweeping
      @sweeping = true
      start_sweeper
    end

    def well_connections
      @server_connections
    end

    def get(id)
      @server_connections[id]
    end

    def aggregate_stats(parsed_data) : String
      result_hash = Hash(String, JSON::Any).new
      @server_connections.values.each do |server_client|
        output = server_client.send_string(parsed_data)
        result_hash[server_client.id] = JSON.parse(output)
      end
      result_hash.to_json
    end

    def send_all(str)
      @server_connections.values.each do |server_client|
        server_client.send_string(str)
      end
    end

    def sample
      count = 0
      server_connection = @server_connections.values.sample
      # Keep smapling until non-sick server
      while !server_connection.sick && count < 100
        count += 1
        server_connection = @server_connections.values.sample
      end
      server_connection
    end

    def sick_server(id)
      begin
        puts "Setting sick server #{id}" if @debug
        restart_connection(id)
      rescue ex
        puts ex.inspect_with_backtrace
      end
    end

    # ------------------------------------
    # --    private
    # ------------------------------------
    def start_sweeper
      spawn do
        loop do
          begin
            sweep_for_sick
            sweep_for_draining
            sleep(@sweep_duration)
          rescue ex
            puts "ServerConnectionCache Sweeper Exception..."
            puts ex.inspect_with_backtrace
          end
        end
      end
    end

    def sweep_for_draining
      begin
        @draining_connection_ids.select! do |id|
          empty = true
          server_client = @server_connections[id]
          output = JSON.parse(server_client.send_string(STATS_HASH)).as_h
          output.select! do |tube, val|
            if tube != "global"
              puts tube + "->" + val.inspect
              if val["ready"].to_s.to_i > 0 && val["reserved"].to_s.to_i > 0
                empty = false
              end
            end
          end
          if empty
            @server_connections.delete(id)
            puts "Removing Drained Server" if @debug
            false
          else
            true
          end
        end
      rescue ex
        puts ex.inspect_with_backtrace
      end
    end

    def sweep_for_sick
      return if @server_connections.size == 1

      @server_connections.each do |id, sc|
        begin
          sick_server(id) unless sc.ping?(10000)
        rescue ex
          sick_server(id)
        end
      end
    end
  end
end

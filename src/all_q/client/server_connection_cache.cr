module AllQ
  class ServerConnectionCache
    SWEEP_DURATION = ENV["SWEEP_DURATION"]? || "10"

    def initialize(servers : Array(String))
      @debug = false # INFER TYPE
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
      @sweeping = false
      @sweep_duration = 10
      @sweep_duration = SWEEP_DURATION.to_i
      @sick_connections = Hash(String, ServerConnection).new
      @server_connections = Hash(String, ServerConnection).new
      servers.each do |server|
        server_uri = server.split(":")
        server_path = server_uri[0].to_s
        port = server_uri[1].to_s
        new_server_connection = ServerConnection.new(server_path.to_s, port.to_s)
        wait_for_ready(new_server_connection)
        @server_connections[new_server_connection.id] = new_server_connection
      end
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
      server_connection = @server_connections.values.sample
    end

    def sick_server(id)
      begin
        puts "Setting sick server #{id}" if @debug
        sick_server_connection = @server_connections.delete(id)
        if sick_server_connection
          @sick_connections[id] = sick_server_connection
        end
      rescue ex
        puts ex.inspect_with_backtrace
      end
    end

    def well_server(id)
      begin
        puts "Setting well server #{id}" if @debug
        well_server_connection = @sick_connections.delete(id)
        if well_server_connection
          @server_connections[id] = well_server_connection
        end
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
            sweep_for_well
            sleep(@sweep_duration)
          rescue ex
            puts "ServerConnectionCache Sweeper Exception..."
            puts ex.inspect_with_backtrace
          end
        end
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

    def sweep_for_well
      @sick_connections.each do |id, sc|
        begin
          puts "Checking sick servers"
          if sc.ping?(1000)
            puts "Readding server #{id}"
            well_server(id)
          end
        rescue ex
          # Not well apparently
        end
      end
    end
  end
end

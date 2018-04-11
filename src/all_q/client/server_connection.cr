module AllQ
  class ServerConnection
    @server_client : ZMQ::Socket
    A_ZAP_DOMAIN      = ENV["A_ZAP_DOMAIN"]? || "roger"
    A_CURVE_SERVERKEY = ENV["A_CURVE_SERVERKEY"]? || "W}@/*{s8T8&/j%H5>>/m+O?MdJO]$Vbo2FC0pAS@"
    A_CURVE_PUBLICKEY = ENV["A_CURVE_PUBLICKEY"]? || "kA3:7cq}Pv+-#j9bNLZIwkWDb[0]71E@kVPl9hg}"
    A_CURVE_SECRETKEY = ENV["A_CURVE_SECRETKEY"]? || "rimy00EMw2WO>sctSIe5rw&9c8*qz*jeg+:S.?!n"

    property id

    def initialize(@server : String, @port : String)
      @restart = false
      context = ZMQ::Context.new
      @server_client = build_socket(context)
      start_server_connection(@server_client)
      @reconnect_count = 0
      @id = Random::Secure.urlsafe_base64(6)
    end

    def build_socket(context) : ZMQ::Socket
      return context.socket(ZMQ::REQ)
    end

    def redirect(server_ip : String, port : String)
      return unless server_ip.size > 0 && port.size > 0
      @server = server_ip
      @port = port
      reconnect
    end

    def admin(server_response)
      vals = JSON.parse(server_response)
      if vals && vals["admin"]
        name = vals["admin"]["name"]
        if "redirect" == name.to_s
          server = vals["admin"]["server"].to_s
          port = vals["admin"]["port"].to_s
          redirect(server, port)
        end
      end
    end

    def send_string(hash : Hash(String, JSON::Type))
      result_string = ""
      begin
        @server_client.send_string(hash.to_json)
      rescue ex
        puts ex.message
      end

      begin
        result_string = @server_client.receive_string
        if result_string.blank?
          reconnect
          # -- Admin results are only ever on 'gets'
        elsif result_string[0..6] == "{\"admin"
          admin(result_string)
          return "{}"
        else
          result = JSON.parse(result_string)
          if result["job"]?
            job_data = result["job"].as_h
            unless job_data.empty?
              job_data["q_server"] = id
            end
          end
          result_string = result.to_json
        end
      rescue ex2
        puts ex2.message
      end
      return result_string
    end

    def reconnect
      return if @restart = true
      puts "Reconnecting..."
      sleep_time = @reconnect_count
      unless sleep_time.nil?
        sleep_time += 1
        @reconnect_count = sleep_time
        sleep(sleep_time)
      end
      @restart = true
    end

    def redirect(server_ip : String, port : String)
      return unless server_ip.size > 0 && port.size > 0
      @server = server_ip
      @port = port
      reconnect
    end

    def start_server_connection(server_client)
      spawn do
        server_client.set_socket_option(::ZMQ::ZAP_DOMAIN, A_ZAP_DOMAIN)
        server_client.set_socket_option(::ZMQ::CURVE_SERVER, 1)
        server_client.set_socket_option(::ZMQ::CURVE_SERVERKEY, A_CURVE_SERVERKEY)
        server_client.set_socket_option(::ZMQ::CURVE_PUBLICKEY, A_CURVE_PUBLICKEY)
        server_client.set_socket_option(::ZMQ::CURVE_SECRETKEY, A_CURVE_SECRETKEY)

        puts "Connecting tcp://#{@server}:#{@port}"
        server_client.connect("tcp://#{@server}:#{@port}")
        @restart = false
        while !@restart
          sleep(0.001)
        end

        # Close and rstart
        server_client.close
        context = ZMQ::Context.new
        @server_client = build_socket(context)
        start_server_connection(@server_client)
      end
    end
  end
end

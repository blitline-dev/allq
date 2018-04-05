require "zeromq"
require "json"
require "./*"

module AllQ
  class Client
    CLIENT_PORT = ENV["TCP_CLIENT_PORT"]? || "7766"

    @server_client : ZMQ::Socket

    def initialize(@server : String, @port : String)
      context = ZMQ::Context.new
      @server_client = build_socket(context)
      start_server_connection(@server_client)
      start_local_proxy(self)
      @restart = false
      @reconnect_count = 0
    end

    def build_socket(context) : ZMQ::Socket
      return context.socket(ZMQ::REQ)
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

    def start_server_connection(server_client)
      spawn do
        server_client.set_socket_option(::ZMQ::ZAP_DOMAIN, "roger")
        server_client.set_socket_option(::ZMQ::CURVE_SERVER, 1)
        server_client.set_socket_option(::ZMQ::CURVE_SERVERKEY, "W}@/*{s8T8&/j%H5>>/m+O?MdJO]$Vbo2FC0pAS@")
        server_client.set_socket_option(::ZMQ::CURVE_PUBLICKEY, "kA3:7cq}Pv+-#j9bNLZIwkWDb[0]71E@kVPl9hg}")
        server_client.set_socket_option(::ZMQ::CURVE_SECRETKEY, "rimy00EMw2WO>sctSIe5rw&9c8*qz*jeg+:S.?!n")

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

    def send(data)
      begin
        hash = AllQ::Parser.parse(data)
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
        end
      rescue ex2
        puts ex2.message
      end
      return result_string
    end

    def something
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

client = AllQ::Client.new(ENV["SERVER_IP"]? || "127.0.0.1", ENV["SERVER_PORT"]? || "5555")
loop do
  sleep(1000)
end

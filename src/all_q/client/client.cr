require "zeromq"
require "json"
require "./*"

module AllQ
  class Client
    SERVER_IP = "127.0.0.1"
    SERVER_PORT = "5555"
    CLIENT_PORT = "7766"

    @server_client : ZMQ::Socket

    def initialize
      context = ZMQ::Context.new
      @server_client = build_socket(context)
      start_server_connection(@server_client)
      start_local_proxy(self)
    end

    def build_socket(context) : ZMQ::Socket
      return context.socket(ZMQ::REQ)
    end

    def start_server_connection(server_client)
      spawn do
        server_client.set_socket_option(::ZMQ::ZAP_DOMAIN, "roger")
        server_client.set_socket_option(::ZMQ::CURVE_SERVER, 1)
        server_client.set_socket_option(::ZMQ::CURVE_SERVERKEY, "W}@/*{s8T8&/j%H5>>/m+O?MdJO]$Vbo2FC0pAS@")
        server_client.set_socket_option(::ZMQ::CURVE_PUBLICKEY, "kA3:7cq}Pv+-#j9bNLZIwkWDb[0]71E@kVPl9hg}")
        server_client.set_socket_option(::ZMQ::CURVE_SECRETKEY, "rimy00EMw2WO>sctSIe5rw&9c8*qz*jeg+:S.?!n")

        puts "Connecting tcp://#{SERVER_IP}:#{SERVER_PORT}"
        server_client.connect("tcp://#{SERVER_IP}:#{SERVER_PORT}")
        loop do
          sleep()
        end
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
      rescue ex2
        puts ex2.message
      end   
      return result_string
    end

    def start_local_proxy(raw_server)
      spawn do
        port = ENV["CL_PORT"]? || CLIENT_PORT
        listen = ENV["CL_LISTEN"]? || "0.0.0.0"
        debug = ENV["CL_DEBUG"]?.to_s == "true"
        allq_dir = "/tmp"

        server = Tcp.new(listen, port.to_i, allq_dir, true, raw_server)
        server.listen()
      end
    end

  end
end

client = AllQ::Client.new
loop do
  sleep(1000)
end
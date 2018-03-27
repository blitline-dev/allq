require "zeromq"
require "./handlers/*"
require "./*"
require "../lib/*"

module AllQ
  class Server
    PORT = "5555"
    TOTAL_FIBERS = 10
    def listen
      # Simple server
      context = ZMQ::Context.new

      server = context.socket(ZMQ::REP) 
      server.set_socket_option(::ZMQ::ZAP_DOMAIN, "roger")
      server.set_socket_option(::ZMQ::CURVE_SERVER, 1)
      server.set_socket_option(::ZMQ::CURVE_SECRETKEY, "HLM9c1VT)cJf3^e7Jkp.x:fK2rvA!5f]Xo71B8nI")


      server.bind("tcp://127.0.0.1:#{PORT}")
      puts "Listening tcp://127.0.0.1:#{PORT}"

      cache_store = CacheStore.new
      request_handler = RequestHandler.new(cache_store)

      loop do
        begin
          in_string = server.receive_string(1)
          unless in_string.blank?
            result = request_handler.process(in_string)
            server.send_string(result.to_s)
          end
          Fiber.yield
        rescue ex
          p "Error in main_loop:allqserver"
          p ex.message
        end
      end
    end
  end
end

AllQ::Server.new.listen

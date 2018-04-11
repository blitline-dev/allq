require "zeromq"
require "./handlers/*"
require "./*"
require "../lib/*"
require "./caches/*"
require "cannon"

module AllQ
  class Server
    PORT         = ENV["SERVER_PORT"]? || "5555"
    TOTAL_FIBERS = 10
    ASYNC        =  1

    def listen
      # Simple server
      context = ZMQ::Context.new

      server = context.socket(::ZMQ::REP)
      server.set_socket_option(::ZMQ::ZAP_DOMAIN, "roger")
      server.set_socket_option(::ZMQ::CURVE_SERVER, 1)
      server.set_socket_option(::ZMQ::CURVE_SECRETKEY, "HLM9c1VT)cJf3^e7Jkp.x:fK2rvA!5f]Xo71B8nI")

      server.bind("tcp://0.0.0.0:#{PORT}")
      puts "Listening tcp://0.0.0.0:#{PORT}"

      cache_store = CacheStore.new
      request_handler = RequestHandler.new(cache_store)
      redirect_handler = RedirectHandler.new(cache_store, request_handler)

      loop do
        begin
          in_string = server.receive_string(ASYNC)
          unless in_string.blank?
            if cache_store.redirect?
              result = redirect_handler.process(in_string)
            else
              result = request_handler.process(in_string)
              server.send_string(result.to_s)
            end
          end
          Fiber.yield
          sleep(0.0001)
        rescue ex
          p "Error in main_loop:allqserver"
          p ex.message
        end
      end
    end
  end
end

puts "version= #{ENV["version"]?}"
AllQ::Server.new.listen

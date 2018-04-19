require "zeromq"
require "./handlers/*"
require "./*"
require "../lib/*"
require "./caches/*"
require "cannon"

module AllQ
  class Server
    PORT              = ENV["SERVER_PORT"]? || "5555"
    TOTAL_FIBERS      = 10
    ASYNC             =  1
    A_CURVE_SECRETKEY = ENV["A_CURVE_SECRETKEY"]? || "HLM9c1VT)cJf3^e7Jkp.x:fK2rvA!5f]Xo71B8nI"
    A_ZAP_DOMAIN      = ENV["A_ZAP_DOMAIN"]? || "roger"

    def listen
      # Simple server
      context = ZMQ::Context.new

      server = context.socket(::ZMQ::REP)
      server.set_socket_option(::ZMQ::ZAP_DOMAIN, A_ZAP_DOMAIN)
      server.set_socket_option(::ZMQ::CURVE_SERVER, 1)
      server.set_socket_option(::ZMQ::CURVE_SECRETKEY, A_CURVE_SECRETKEY)

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

if AllQ::Server::A_CURVE_SECRETKEY == "HLM9c1VT)cJf3^e7Jkp.x:fK2rvA!5f]Xo71B8nI"
  public_key, private_key = ZMQ::Util.curve_keypair
  puts ""
  puts "WARNING:"
  puts "You are using the DEFAULT CURVE secret key! Do not do this unless you are only testing locally."
  puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  puts ""
  puts "I have generated a new CURVE public and private key for you here:"
  puts "A_CURVE_PUBLICKEY=\"#{public_key}\""
  puts "A_CURVE_SECRETKEY=\"#{private_key}\""
  puts ""
  puts "Please record and update your client and server containers with these environment values"
  puts "It's OK if you don't, I will generate new ones again next time you run me."
  puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
end
puts ""
puts "version= #{ENV["version"]?}"
puts "--------------------------------------"
puts "-- Running in #{BaseSerDe::SERIALIZE ? "serialize" : "non-serialized"} mode"
puts "--------------------------------------"
AllQ::Server.new.listen

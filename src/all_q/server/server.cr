require "zeromq"
require "./handlers/*"
require "./*"
require "../lib/*"
require "./caches/*"
require "cannon"
require "base64"

module AllQ
  class Server
    PORT              = ENV["SERVER_PORT"]? || "5555"
    TOTAL_FIBERS      = 10
    ASYNC             =  1
    A_CURVE_SECRETKEY = ENV["A_CURVE_SECRETKEY"]? || "SExNOWMxVlQpY0pmM15lN0prcC54OmZLMnJ2QSE1Zl1YbzcxQjhuSQ=="
    A_CURVE_PUBLICKEY = ENV["A_CURVE_PUBLICKEY"]? || "V31ALyp7czhUOCYvaiVINT4+L20rTz9NZEpPXSRWYm8yRkMwcEFTQA=="
    A_ZAP_DOMAIN      = ENV["A_ZAP_DOMAIN"]? || "roger"

    def listen
      puts "A_CURVE_SECRETKEY = #{A_CURVE_SECRETKEY[0..4]}..."
      puts "A_CURVE_PUBLICKEY = #{A_CURVE_PUBLICKEY[0..4]}..."

      # Simple server
      context = ZMQ::Context.new

      server = context.socket(::ZMQ::REP)
      server.set_socket_option(::ZMQ::ZAP_DOMAIN, A_ZAP_DOMAIN)
      server.set_socket_option(::ZMQ::CURVE_SERVER, 1)
      server.set_socket_option(::ZMQ::CURVE_SECRETKEY, Base64.decode_string(A_CURVE_SECRETKEY))
      server.set_socket_option(::ZMQ::CURVE_PUBLICKEY, Base64.decode_string(A_CURVE_PUBLICKEY))
      server.set_socket_option(::ZMQ::REQ_CORRELATE, 1)
      server.set_socket_option(::ZMQ::IMMEDIATE, 1)

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

if AllQ::Server::A_CURVE_SECRETKEY == "SExNOWMxVlQpY0pmM15lN0prcC54OmZLMnJ2QSE1Zl1YbzcxQjhuSQ=="
  public_key, private_key = ZMQ::Util.curve_keypair
  public_key_s, private_key_s = ZMQ::Util.curve_keypair
  puts ""
  puts "WARNING:"
  puts "You are using the DEFAULT CURVE secret key! Do not do this unless you are only testing locally."
  puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  puts ""
  puts "I have generated a new CURVE public and private key for you here:"
  puts "client:"
  puts "export A_CURVE_PUBLICKEY=\"#{Base64.strict_encode(public_key)}\""
  puts "export A_CURVE_SECRETKEY=\"#{Base64.strict_encode(private_key)}\""
  puts "export A_CURVE_SERVER_PUBLICKEY=\"#{Base64.strict_encode(public_key_s)}\""
  puts ""
  puts "server:"
  puts "export A_CURVE_PUBLICKEY=\"#{Base64.strict_encode(public_key_s)}\""
  puts "export A_CURVE_SECRETKEY=\"#{Base64.strict_encode(private_key_s)}\""
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

require "socket"

class Tcp
  TOTAL_FIBERS = 200

  def initialize(@host : String, @port : Int32, @debug : Bool, @sender : AllQ::Client)
    @connections = 0
    @version = ENV["CL_VERSION"]? || "0.0.0.0"
  end

  def get_socket_data(socket : TCPSocket)
    begin
      socket.each_line do |line|
        puts line.to_s if @debug
        yield(line)
      end
    rescue ex
      if @debug
        puts ex.inspect_with_backtrace
        puts "From Socket Address:" + socket.remote_address.to_s if socket.remote_address
      end
    end
  end

  def reader(socket : TCPSocket)
    get_socket_data(socket) do |data|
      if data == "stats\n"
        p "Stats"
        stats_response(socket)
        return
      end

      puts "Received: #{data}" if @debug
      if data && data.size > 3
        begin
          do_stuff(data, socket)
        rescue ex
          p ex.inspect_with_backtrace
          p "Data:#{data}"
        end
      end
    end
  end

  def stats_response(socket : TCPSocket)
    data = {
      "version"     => @version,
      "debug"       => @debug,
      "connections" => @connections,
      "port"        => @port,
      "available"   => TOTAL_FIBERS,
    }
    p "Stats Response #{data}"
    socket.puts(data.to_s)
  end

  def spawn_listener(socket_channel : Channel)
    TOTAL_FIBERS.times do
      spawn do
        loop do
          begin
            socket = socket_channel.receive
            socket.read_timeout = 3
            socket.tcp_keepalive_count = 1
            @connections += 1
            reader(socket)
            socket.close
            @connections -= 1
          rescue ex
            p "Error in spawn_listener"
            puts ex.inspect_with_backtrace
          end
        end
      end
    end
  end

  def listen
    ch = build_channel
    puts "Creating TCP #{[@host, @port]}..."
    server = TCPServer.new(@host, @port)

    spawn_listener(ch)
    puts "Local proxy @ #{@port}"
    loop do
      begin
        socket = server.accept
        ch.send socket
      rescue ex
        p "Error in tcp:loop!"
        p ex.inspect_with_backtrace
      end
    end
  end

  def build_channel
    Channel(TCPSocket).new
  end

  def do_stuff(data, socket)
    result = @sender.send(data)
    socket.puts(result)
  end
end

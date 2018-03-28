require "socket"

class Tcp
  TOTAL_FIBERS = 5
  
  def initialize(@host : String, @port : Int32, @base_dir : String, @debug : Bool, @sender : AllQ::Client)

    @connections = 0
    @version = ENV["CL_VERSION"]? || "0.0.0.0"
  end

  def get_socket_data(socket : TCPSocket)
    data = nil
    begin
      data = socket.gets
    rescue ex
      if @debug
        puts ex.inspect_with_backtrace
        puts "From Socket Address:" + socket.remote_address.to_s if socket.remote_address
      end
    end
    return data
  end

  def reader(socket : TCPSocket)
    data = get_socket_data(socket)

    if data == "stats\n"
      p "Stats"
      stats_response(socket)
      return
    end

    puts "Recieved: #{data}" if @debug
    while data
      if data && data.size > 5
        begin
          do_stuff(data, socket)
        rescue ex
          p ex.message
          p "Data:#{data}"
        end
        data = get_socket_data(socket)
      end
    end
  end

  def stats_response(socket : TCPSocket)
    data = {
      "version" => @version,
      "debug" => @debug,
      "connections" => @connections,
      "port" =>  @port,
      "available" => TOTAL_FIBERS
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
            @connections += 1
            reader(socket)
            socket.close
            @connections -= 1
          rescue ex
            p "Error in spawn_listener"
            p ex.message
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
    begin
      puts "Local proxy @ #{@port}"
      loop do
        socket = server.accept
        ch.send socket
      end
    rescue ex
      p "Error in tcp:loop!"
      p ex.message
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


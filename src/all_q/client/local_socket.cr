require "socket"
require "file_utils"

class AllQSocket
  TOTAL_FIBERS = 20
  UNIX_SOCKET_PATH = "/tmp/allq_client.sock"

  def initialize(@debug : Bool, @sender : AllQ::Client)
    @connections = 0
    @version = ENV["CL_VERSION"]? || "0.0.0.0"
  end

  def get_socket_data(socket : Socket)
    data = nil
    begin
      data = socket.gets
    rescue ex
      if @debug
        puts ex.inspect_with_backtrace
      end
    end
    return data
  end

  def reader(socket : Socket)
    data = get_socket_data(socket)

    if data == "stats\n"
      p "Stats"
      stats_response(socket)
      return
    end

    puts "Received: #{data}" if @debug
    while data
      if data && data.size > 3
        begin
          do_stuff(data, socket)
        rescue ex
          p ex.inspect_with_backtrace
          p "Data:#{data}"
        end
      end
      data = get_socket_data(socket)
    end
  end

  def stats_response(socket : Socket)
    data = {
      "version"     => @version,
      "debug"       => @debug,
      "connections" => @connections,
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
            socket.read_timeout = 10
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
    puts "Creating Socket at  #{UNIX_SOCKET_PATH}..."
    FileUtils.rm(UNIX_SOCKET_PATH) if File.exists?(UNIX_SOCKET_PATH)
    server = UNIXServer.new(UNIX_SOCKET_PATH)

    spawn_listener(ch)
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
    Channel(Socket).new
  end

  def do_stuff(data, socket)
    result = @sender.send(data)
    socket.puts(result)
  end
end

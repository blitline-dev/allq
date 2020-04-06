require "base64"
require "digest"

module AllQ
  class ServerConnection
    @server_client : ZMQ::Socket
    A_ZAP_DOMAIN              = ENV["A_ZAP_DOMAIN"]? || "roger"
    A_CURVE_SERVER_PUBLIC_KEY = ENV["A_CURVE_SERVER_PUBLICKEY"]? || "V31ALyp7czhUOCYvaiVINT4+L20rTz9NZEpPXSRWYm8yRkMwcEFTQA=="
    A_CURVE_PUBLICKEY         = ENV["A_CURVE_PUBLICKEY"]? || "a0EzOjdjcX1QdistI2o5Yk5MWkl3a1dEYlswXTcxRUBrVlBsOWhnfQ=="
    A_CURVE_SECRETKEY         = ENV["A_CURVE_SECRETKEY"]? || "cmlteTAwRU13MldPPnNjdFNJZTVydyY5YzgqcXoqamVnKzpTLj8hbg=="

    property id, server, port, sick, full_path

    def initialize(@server : String, @port : String)
      @mutex = Mutex.new
      @exit = false
      @ready = false
      @sick = true
      @debug = false # INFER TYPE
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
      @restart = false
      context = ZMQ::Context.new
      @server_client = build_socket(context)
      start_server_connection(@server_client)
      @reconnect_count = 1
      @full_path = ""
      @full_path = @server + ":" + @port
      @id = Digest::SHA1.base64digest(@server)[0..6]
      puts "A_CURVE_SECRETKEY = #{A_CURVE_SECRETKEY[0..4]}..."
      puts "A_CURVE_PUBLICKEY = #{A_CURVE_PUBLICKEY[0..4]}..."
      puts "A_CURVE_SERVER_PUBLIC_KEY = #{A_CURVE_SERVER_PUBLIC_KEY[0..4]}..."
    end

    def ready?
      @ready
    end

    def build_socket(context) : ZMQ::Socket
      return context.socket(ZMQ::REQ)
    end

    def close
      @exit = true
      @restart = true
      @server_client.close
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

    def final_send_string(string, timeout)
      val = ""
      @mutex.synchronize do
        @server_client.send_string(string)
        val = @server_client.receive_string
      end
      @reconnect_count = 0
      return val
    end

    def ping?(timeout = 5000)
      good = false
      begin
        result_string = final_send_string("ping", timeout)
        good = true if result_string == "pong"
      rescue ex
        puts ex.inspect_with_backtrace if @debug
      end
      puts "Failed ping...#{@id}" unless good
      @sick = !good
      return good
    end

    def send_string(hash : JSON::Any)
      result_string = ""
      begin
        string_to_send = hash.to_json
        string_to_send = string_to_send.gsub(/\"job_id\"\s*:\s*\".*?\,(.*?)\"/, "\"job_id\":\"\\1\"")
        string_to_send = string_to_send.gsub(/\"parent_id\"\s*:\s*\".*?\,(.*?)\"/, "\"parent_id\":\"\\1\"")

        puts "Sending #{string_to_send}" if @debug
      rescue ex
        puts "Exception1 is send_string"
        puts ex.inspect_with_backtrace
      end

      begin
        result_string = final_send_string(string_to_send, 5000).strip
        puts "Got #{result_string}" if @debug

        if result_string.blank?
          reconnect
          # -- Admin results are only ever on 'gets'
        elsif result_string[0..6] == "{\"admin"
          admin(result_string)
          return "{}"
        else
          result_string = result_string.gsub(/\"job_id\"\s*:\s*\"(.*?)\"/, "\"job_id\":\"#{id},\\1\"")
          result_string = result_string.gsub(/\"parent_id\"\s*:\s*\"(.*?)\"/, "\"parent_id\":\"#{id},\\1\"")
        end
      rescue ex2
        reconnect
        puts "Exception2 is send_string"
        puts ex2.inspect_with_backtrace
        raise "Failed to talk to server side"
      end
      return result_string
    end

    def reconnect
      return if @restart
      sleep_time = @reconnect_count
      unless sleep_time == 0
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
      @id = Random::Secure.urlsafe_base64(6)
      reconnect
    end

    def start_server_connection(server_client)
      spawn do
        server_client.set_socket_option(::ZMQ::ZAP_DOMAIN, A_ZAP_DOMAIN)
        server_client.set_socket_option(::ZMQ::CURVE_SERVER, 1)
        server_client.set_socket_option(::ZMQ::REQ_CORRELATE, 1)
        server_client.set_socket_option(::ZMQ::IMMEDIATE, 1)
        server_client.set_socket_option(::ZMQ::RCVTIMEO, 5000)
        server_client.set_socket_option(::ZMQ::LINGER, 0)
        # server_client.set_socket_option(::ZMQ::RECONNECT_IVL, 1000)
        # server_client.set_socket_option(::ZMQ::RECONNECT_IVL_MAX, 60000)
        server_client.set_socket_option(::ZMQ::CURVE_SERVERKEY, Base64.decode_string(A_CURVE_SERVER_PUBLIC_KEY))
        server_client.set_socket_option(::ZMQ::CURVE_PUBLICKEY, Base64.decode_string(A_CURVE_PUBLICKEY))
        server_client.set_socket_option(::ZMQ::CURVE_SECRETKEY, Base64.decode_string(A_CURVE_SECRETKEY))

        puts "Connecting tcp://#{@server}:#{@port}"
        server_client.connect("tcp://#{@server}:#{@port}")
        @restart = false
        @ready = true
        @sick = false
        while !@restart
          sleep(0.5)
        end
        unless @exit
          # Close and restart
          server_client.close
          context = ZMQ::Context.new
          @server_client = build_socket(context)
          start_server_connection(@server_client)
        end
      end
    end
  end
end

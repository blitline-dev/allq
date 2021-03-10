module ZMQ
  class Socket
    def send_string(string, flags = 0, timeout = 10.seconds)
      part = @message_type.new(string)
      send_message(part, flags, timeout)
    end

    def send_message(message : AbstractMessage, flags = 0, timeout = 10.seconds)
      # we always send in non block mode and add a wait writable, caller should close the message when done
      loop do
        rc = LibZMQ.msg_send(message.address, @socket, flags | ZMQ::DONTWAIT)
        if rc == -1
          if Util.errno == Errno::EAGAIN.to_i
            wait_writable(timeout)
          else
            raise Util.error_string
          end
        else
          return Util.resultcode_ok?(rc)
        end
      end
    ensure
      if (writers = @writers.get?) && !writers.empty?
        add_write_event
      end
    end
  end
end

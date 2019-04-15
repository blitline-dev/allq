module AllQ
    class DrainHandler < BaseClientHandler
      # -------------------------------------------------
      # Sets drain state for server
      # Drain state makes client ignore server for PUT sample
      # but GETs still work. When server is empty, removes
      # server from pool
      # -------------------------------------------------
      def process(parsed_data)
        result_hash = Hash(String, String).new
        server_id = parsed_data["params"]["server_id"].to_s
        result_hash["server_id"] = server_id
        @server_connections.drain(server_id)  
        return result_hash.to_json
      end
    end
  end
  
module AllQ
    class AddServerHandler < BaseClientHandler
      # -------------------------------------------------
      # Adds server to cluser
      # -------------------------------------------------
      def process(parsed_data)
        result_hash = Hash(String, String).new
        server_url = parsed_data["params"]["server_url"].to_s
        result_hash["server_url"] = server_url
        @server_connections.add_server(server_url)  
        return result_hash.to_json
      end
    end
  end
  
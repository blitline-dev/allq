module AllQ
  class ClientPeekHandler < BaseClientHandler
    # -------------------------------------------------
    # Peek needs to look through all queues, not just a
    # sampled one. It should iterator until it finds
    # one and return in. Otherwise nothing to return
    # -------------------------------------------------
    def process(parsed_data)
      result_hash = Hash(String, JSON::Any)
      output = "{}"
      # -- Run through connections...
      @server_connections.values.each do |server_client|
        output = server_client.send_string(parsed_data)
        server_response = JSON.parse(output)
        # -- If we find one, return it
        if server_response["job"]? && server_response["job"]["job_id"]?
          return output
        end
      end
      # -- ...otherwise return the last one we saw (which is empty)
      return output
    end
  end
end

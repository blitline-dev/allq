module AllQ
  class PingAggregator < BaseClientHandler
    # -------------------------------------------------
    # Stats need to get ALL stats from servers
    # and aggregate them.
    # -------------------------------------------------
    def process(parsed_data) : String
      result_hash = Hash(String, String).new
      @server_connections.well_connections.values.each do |server_client|
        output = server_client.ping?.to_s
        result_hash[server_client.id] = output
      end
      result_hash.to_json
    end
  end
end

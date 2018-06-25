module AllQ
  class StatsAggregator < BaseClientHandler
    # -------------------------------------------------
    # Stats need to get ALL stats from servers
    # and aggregate them.
    # -------------------------------------------------
    def process(parsed_data) : String
      result_hash = Hash(String, JSON::Any).new
      @server_connections.values.each do |server_client|
        output = server_client.send_string(parsed_data)
        result_hash[server_client.id] = JSON.parse(output)
      end
      result_hash.to_json
    end
  end
end

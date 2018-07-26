module AllQ
  class StatsAggregator < BaseClientHandler
    # -------------------------------------------------
    # Stats need to get ALL stats from servers
    # and aggregate them.
    # -------------------------------------------------
    def process(parsed_data) : String
      result_hash = Hash(String, JSON::Any).new
      @server_connections.aggregate_stats(parsed_data)
    end
  end
end

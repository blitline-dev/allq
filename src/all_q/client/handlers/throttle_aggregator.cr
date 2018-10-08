module AllQ
    class ThrottleAggregator < BaseClientHandler
      # -------------------------------------------------
      # Stats need to get ALL stats from servers
      # and aggregate them.
      # -------------------------------------------------
      def process(parsed_data) : String
        result_hash = Hash(String, String).new

        tube = parsed_data["params"]["tube"]
        tps = parsed_data["params"]["tps"].to_s.to_i
        return @server_connections.throttle(tube, tps)
      end
    end
  end
  
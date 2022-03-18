module AllQ
  class ThrottleAggregator < BaseClientHandler
    # -------------------------------------------------
    # Stats need to get ALL stats from servers
    # and aggregate them.
    # -------------------------------------------------
    def process(parsed_data) : String
      result_hash = Hash(String, String).new

      tube = parsed_data["params"]["tube"]
      tps = parsed_data["params"]["tps"].to_s.to_i(strict: false)
      return throttle(tube, tps)
    end

    def build_throttle_json(tube_name, tps)
      result = JSON.build do |json|
        json.object do
          json.field "action", "throttle"
          json.field "params" do
            json.object do
              json.field "tube", tube_name
              json.field "tps", tps.to_s
            end
          end
        end
      end
      return result
    end

    def throttle(tube_name, tps)
      well_connections = @server_connections.well_connections
      result_hash = Hash(String, JSON::Any).new
      count = well_connections.size
      rate = tps.to_i / count
      json = build_throttle_json(tube_name, rate)

      well_connections.values.each do |server_client|
        output = server_client.send_string(JSON.parse(json))
        result_hash[server_client.id] = JSON.parse(output)
      end
      result_hash.to_json
    end
  end
end

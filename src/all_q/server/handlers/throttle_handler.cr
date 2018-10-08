module AllQ
    class ThrottleHandler < BaseHandler
      def process(json : JSON::Any)
        return_data = Hash(String, Hash(String, String)).new
        data = normalize_json_hash(json)
        tube_name = data["tube"]?
        tps = data["tps"]?
        output = Hash(String, String).new
        puts data.inspect
        if tube_name && tps
          @cache_store.tubes[tube_name].set_throttle(tps.to_i)
          output["tube"] = tube_name.to_s
          output["tps"] = tps.to_s
          return_data["throttle"] = output
        else
          raise "Failed to set throttle because tube name or tps is invalid"
        end
  
        return return_data
      end
    end
  end
  
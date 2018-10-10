module AllQ
    class ThrottleHandler < BaseHandler
      def process(json : JSON::Any)
        data = normalize_json_hash(json)
        tube_name = data["tube"]?
        tps = data["tps"]?
        handler_response = HandlerResponse.new("throttle")

        if tube_name && tps
          handler_response.value = tps.to_s
          @cache_store.tubes[tube_name].set_throttle(tps.to_i)
        else
          raise "Failed to set throttle because tube name or tps is invalid"
        end
  
        return handler_response
      end
    end
  end
  
require "./base_handler"

module AllQ
  class AdminHandler < BaseHandler
    def process(json : JSON::Any)
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      output = Hash(String, String).new
      action_type = data["action_type"]

      if action_type && action_type.to_s == "redirect"
        output["action_type"] = "redirect"
        @cache_store.set_redirect_info(data["server"], data["port"])
      end

      if action_type && action_type.to_s == "set_throttle"
        output["action_type"] = "set_throttle"
        tube_name = data["name"]
        throttle_tps = data["tps"]
        output["name"] = tube_name
        output["tps"] = throttle_tps
        tube = @cache_store.tubes.get(tube_name)
        if tube
          tube.set_throttle(throttle_tps.to_i)
        end
      end

      return_data["result"] = output
      return return_data
    end
  end
end

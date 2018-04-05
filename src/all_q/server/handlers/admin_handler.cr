require "./base_handler"

module AllQ
  class AdminHandler < BaseHandler
    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      output = Hash(String, String).new
      action_type = data["action_type"]

      if action_type && action_type.to_s == "redirect"
        output["action_type"] = "redirect"
        @cache_store.set_redirect_info(data["server"], data["port"])
      end
      return_data["result"] = output
      return return_data
    end
  end
end

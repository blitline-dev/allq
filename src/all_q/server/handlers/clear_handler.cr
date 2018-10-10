require "./base_handler"

# ---------------------------------
# Action: clear
# Params:
#     cache_type : all (clear ALL queues, like restarting server)
#     |
#     tube : <tube name> (clear tube)
# ---------------------------------

module AllQ
  class ClearHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      handler_response = HandlerResponse.new("clear")

      cache_type = data["cache_type"]?
      tube_name = data["tube"]?

      if cache_type.to_s == "all"
        @cache_store.clear_all
        handler_response.action = "clear_all"
      elsif tube_name
        @cache_store.tubes[tube_name].clear
      end
      return handler_response
    end
  end
end

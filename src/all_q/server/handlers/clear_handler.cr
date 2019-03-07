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

      tube_name = data["tube"]?

      if tube_name
        @cache_store.tubes[tube_name].clear
        @cache_store.reserved.clear_by_tube(tube_name)
        @cache_store.buried.clear_by_tube(tube_name)
        @cache_store.parents.clear_by_tube(tube_name)
      end
      return handler_response
    end
  end
end

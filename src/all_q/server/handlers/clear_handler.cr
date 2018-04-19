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
    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      output = Hash(String, String).new
      cache_type = data["cache_type"]?
      tube_name = data["tube"]?

      if cache_type.to_s == "all"
        @cache_store.clear_all
        output["clear"] = cache_type.to_s
      elsif tube_name
        @cache_store.tubes[tube_name].clear
      end
      return_data["result"] = output
      return return_data
    end
  end
end

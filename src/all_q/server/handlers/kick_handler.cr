require "./base_handler"

# ---------------------------------
# Action: kick
# Params:
#     tube : <tube name> (kick job from tube into ready)
# ---------------------------------

module AllQ
  class KickHandler < BaseHandler
    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job_id = @cache_store.buried.kick(data["tube"])
      output = Hash(String, String).new
      if job_id
        output["job_id"] = job_id
        return_data["kick"] = output
      end
      return return_data
    end
  end
end

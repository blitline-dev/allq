require "./base_handler"

# ---------------------------------
# Action: kick
# Params:
#     tube : <tube name> (kick job from tube into ready)
# ---------------------------------

module AllQ
  class KickHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      job_id = @cache_store.buried.kick(data["tube"])
      handler_response = HandlerResponse.new("kick")

      if job_id
        handler_response.job_id = job_id
      end
      return handler_response
    end
  end
end

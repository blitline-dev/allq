require "./base_handler"

# ---------------------------------
# Action: bury
# Params:
#     job_id : <job id> (clear job from buried or reserved)

module AllQ
  class BuryHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      job_id = data["job_id"]?
      handler_response = HandlerResponse.new("bury")
      handler_response.job_id = job_id

      if job_id
        job = @cache_store.reserved.bury(job_id)
        handler_response.error = "Couldn't bury job_id = #{job_id}" unless job
      else
        handler_response.error = "Job ID not found in reserved"
      end

      return handler_response
    end
  end
end

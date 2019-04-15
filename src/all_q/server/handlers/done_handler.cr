require "./base_handler"

# ---------------------------------
# Action: done
# Params:
#     job_id : <job id> (mark job as done)
# ---------------------------------

module AllQ
  class DoneHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      job_id = data["job_id"]?
      handler_response = HandlerResponse.new("done")

      if job_id
        job = @cache_store.reserved.done(job_id)
        handler_response.job_id = job_id
        handler_response.error = "Couldn't find job job_id = #{job_id} to set done" unless job
      else
        raise "Job ID not found in reserved"
      end

      return handler_response
    end
  end
end

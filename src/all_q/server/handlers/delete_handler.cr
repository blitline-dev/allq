require "./base_handler"

# ---------------------------------
# Action: delete
# Params:
#     job_id : <job id> (clear job from buried or reserved)
# ---------------------------------

module AllQ
  class DeleteHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      job_id = data["job_id"]? || "Job ID not found in reserved or buried. #{data.inspect}"
      found = find_and_delete(job_id, data)
      handler_response = HandlerResponse.new("delete")
      handler_response.job_id = job_id
      handler_response.error = "Job ID not found in reserved or buried." unless found
      return handler_response
    end

    def find_and_delete(job_id, data)
      job = @cache_store.reserved.delete(job_id)
      if job
        return true
      end
      job = @cache_store.buried.delete(job_id)
      if job
        return true
      end

      # We only delete reserved and buried jobs by default
      # If "tube" is present, we will parse through ALL "ready" tube
      # prority queues and try to find the job, this can be a 
      # very expensive operation on large tubes.
      if data["tube"]?
        tube = @cache_store.tubes[data["tube"]]
        tube.delete_job(job_id)
      end

      return false
    end
  end
end

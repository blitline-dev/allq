module AllQ
  class TouchHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      job_id = data["job_id"]?
      handler_response = HandlerResponse.new("touch")
      if job_id
        @cache_store.reserved.touch(job_id)
        handler_response.job_id = job_id
      else
        raise "Job ID not found in reserved"
      end

      return handler_response
    end
  end
end

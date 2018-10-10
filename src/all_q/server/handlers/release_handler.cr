module AllQ
  class ReleaseHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      job_id = data["job_id"]?
      delay = data["delay"]? ? data["delay"].to_i(strict: false) : 0
      handler_response = HandlerResponse.new("release")

      if job_id
        @cache_store.reserved.release(job_id, delay.to_i32)
        handler_response.job_id = job_id
      else
        raise "Job ID not found in reserved"
      end

      return handler_response
    end
  end
end

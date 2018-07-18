module AllQ
  class ReleaseHandler < BaseHandler
    def process(json : JSON::Any)
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job_id = data["job_id"]?
      delay = data["delay"]? || 0
      output = Hash(String, String).new
      if job_id
        @cache_store.reserved.release(job_id, delay)
        output["job_id"] = job_id.to_s
        return_data["release"] = output
      else
        raise "Job ID not found in reserved"
      end

      return return_data
    end
  end
end

module AllQ
  class TouchHandler < BaseHandler
    def process(json : JSON::Any)
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job_id = data["job_id"]?
      output = Hash(String, String).new
      if job_id
        @cache_store.reserved.touch(job_id)
        output["job_id"] = job_id.to_s
        return_data["touch"] = output
      else
        raise "Job ID not found in reserved"
      end

      return return_data
    end
  end
end

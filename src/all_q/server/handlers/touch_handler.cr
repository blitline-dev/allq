module AllQ
  class TouchHandler < BaseHandler

    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      @cache_store.reserved.get(data["job_id"])
      job_id = data["job_id"]?
      output = Hash(String, String).new
      if job_id
        @cache_store.reserved.touch(job_id)
        output["touch"] = job_id
      else
        raise "Job ID not found in reserved"
      end

      return return_data
    end
  end
end
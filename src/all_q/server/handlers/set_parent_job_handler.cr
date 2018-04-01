module AllQ
  class SetParentJobHandler < BaseHandler

    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job = AllQ::Job.new(data, data["tube"])
 
      timeout = data["timeout"]? ? data["timeout"].to_i : 3600
      run_on_timeout = data["run_on_timeout"]? ? data["run_on_timeout"].downcase == "true" : false
      @cache_store.parents.set_job_as_parent(job, timeout, run_on_timeout)
      if data["limit"]?
        @cache_store.parents.set_limit(job.id, data["limit"].to_i)
      end
      result = Hash(String, String).new
      result["id"] = job.id
      return_data["job"] = result

      return return_data
    end

    

  end
end
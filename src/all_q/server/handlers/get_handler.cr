module AllQ
  class GetHandler < BaseHandler

    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job = @cache_store.tubes[data["tube"]].get
      puts "No jobs..."
      if job
        @cache_store.reserved.set_job_reserved(job)
        return_data["job"] = job.to_hash
      else
         return_data["job"] = Hash(String, String).new
      end
      return return_data
    end
  end
end
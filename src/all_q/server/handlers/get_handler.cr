require "./base_handler"

# ---------------------------------
# Action: get
# Params: <none>
# ---------------------------------

module AllQ
  class GetHandler < BaseHandler
    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job = @cache_store.tubes[data["tube"]].get
      if job
        @cache_store.reserved.set_job_reserved(job)
        return_data["job"] = JobFactory.to_hash(job)
      else
        return_data["job"] = Hash(String, String).new
      end
      return return_data
    end
  end
end

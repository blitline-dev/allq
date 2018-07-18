require "./base_handler"

# ---------------------------------
# Action: bury
# Params:
#     job_id : <job id> (clear job from buried or reserved)

module AllQ
  class BuryHandler < BaseHandler
    def process(json : JSON::Any)
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job_id = data["job_id"]?
      output = Hash(String, String).new
      if job_id
        job = @cache_store.reserved.bury(job_id)
        output["bury"] = job_id
        return_data["job"] = output
      else
        raise "Job ID not found in reserved"
      end

      return return_data
    end
  end
end

require "./base_handler"

# ---------------------------------
# Action: delete
# Params:
#     job_id : <job id> (clear job from buried or reserved)
# ---------------------------------

module AllQ
  class DeleteHandler < BaseHandler
    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job_id = data["job_id"]? || "Job ID not found in reserved or buried. #{data.inspect}"
      found = find_and_delete(job_id)
      output = Hash(String, String).new
      if found
        output["deleted"] = job_id
      else
        output["job_id"] = job_id
        output["error"] = "Job ID not found in reserved or buried."
      end
      return_data["delete"] = output
      return return_data
    end

    def find_and_delete(job_id)
      job = @cache_store.reserved.delete(job_id)
      if job
        return true
      end
      job = @cache_store.buried.delete(job_id)
      if job
        return true
      end
      return false
    end
  end
end

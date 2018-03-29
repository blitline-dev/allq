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
    end

    def find_and_delete(job_id)
      return true if @cache_store.reserved.delete(job_id)
      return true if @cache_store.buried.delete(job_id)
      return false
    end

  end
end
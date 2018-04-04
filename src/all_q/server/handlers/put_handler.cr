module AllQ
  class PutHandler < BaseHandler
    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)

      priority = data["priority"]? ? data["priority"].to_i : 5
      job = JobFactory.new(data, data["tube"], priority).get_job
      job.id = Random::Secure.urlsafe_base64(16)
      tube_name = data["tube"]

      delay = data["delay"]? ? data["delay"] : 0

      @cache_store.tubes[tube_name].put(job, priority.to_i, delay)
      if job.parent_id && !job.parent_id.to_s.blank?
        @cache_store.parents.child_started(job.parent_id)
      end

      result = Hash(String, String).new
      result["job_id"] = job.id
      return_data["job"] = result
      return return_data
    end
  end
end

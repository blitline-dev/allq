require "./base_handler"

# ---------------------------------
# Action: put
# Params:
#     priority : <priority> (default 1-10, 1 being highest priority)
#     tube : <tube> (Tube name)
#     delay : <delay> (Delay before ready)
# ---------------------------------

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
      if delay == 0
        delay = -1 # Since we only have 1 second granularity, force to be active now
      end

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

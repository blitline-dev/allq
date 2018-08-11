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
    def process(json : JSON::Any)
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)

      job = JobFactory.build_job_factory_from_hash(json).get_job
      job.id = Random::Secure.urlsafe_base64(16)
      tube_name = data["tube"]
      priority = job.priority
      delay = data["delay"]? ? data["delay"].to_s.to_i(strict: false) : 0

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

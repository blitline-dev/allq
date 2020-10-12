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
      handler_response = HandlerResponse.new("put")
      data = normalize_json_hash(json)

      job = JobFactory.build_job_factory_from_hash(json).get_job
      job.id = Random::Secure.urlsafe_base64(16)
      tube_name = data["tube"]
      priority = job.priority
      delay = data["delay"]? ? data["delay"].to_s.to_i(strict: false) : 0

      if @cache_store.fair_queue.is_fair_queue(tube_name)
        shard_key = data["shard_key"]?
        if shard_key.nil?
          raise "Shard key required for Fair Queue (fq-) tubes"
        else
          tube_name = fair_queue_from_put_shard(tube_name, shard_key)
          job.tube = tube_name
        end
      end

      @cache_store.tubes[tube_name].put(job, priority.to_i, delay)

      if job.parent_id && !job.parent_id.to_s.blank?
        @cache_store.parents.child_started(job.parent_id)
      end

      handler_response.job_id = job.id
      return handler_response
    end
  end
end

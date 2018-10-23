module AllQ
  class SetParentJobHandler < BaseHandler
    def process(json : JSON::Any)
      handler_response = HandlerResponse.new("set_parent")

      data = normalize_json_hash(json)
      job = JobFactory.build_job_factory_from_hash(json).get_job
      @cache_store.tubes.get(job.tube)

      timeout = data["timeout"]? ? data["timeout"].to_i : 3600
      run_on_timeout = data["run_on_timeout"]? ? data["run_on_timeout"].downcase == "true" : false

      @cache_store.parents.set_job_as_parent(job, timeout, run_on_timeout)
      if data["limit"]?
        @cache_store.parents.set_limit(job.id, data["limit"].to_i) unless data["limit"].to_s.empty?
      end

      handler_response.job_id = job.id
      handler_response.job = JobFactory.to_hash(job)
      return handler_response
    end
  end
end

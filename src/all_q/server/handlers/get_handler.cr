require "./base_handler"

# ---------------------------------
# Action: get
# Params: <none>
# ---------------------------------

module AllQ
  class GetHandler < BaseHandler
    def process(json : JSON::Any) : HandlerResponse | HandlerResponseMultiple
      data = normalize_json_hash(json)
      count = data["count"]? ? data["count"].to_i : 1
      delete_on_get = data["delete"]?

      if count == 1
        return build_single_job(data, delete_on_get)
      else
        return build_multiple_job(data, delete_on_get, count)
      end
    end

    def build_single_job(data : Hash(String, String), delete_on_get) : HandlerResponse
      handler_response = HandlerResponse.new("get")

      job = @cache_store.tubes[data["tube"]].get
      if job
        @cache_store.reserved.set_job_reserved(job)
        if delete_on_get
          @cache_store.reserved.delete(job.id)
        end
        handler_response.job = JobFactory.to_hash(job)
      else
        handler_response.job = Hash(String, String).new
      end
      return handler_response
    end

    def build_multiple_job(data : Hash(String, String), delete_on_get, count) : HandlerResponseMultiple
      handler_response = HandlerResponseMultiple.new("get")

      count.times do
        job = @cache_store.tubes[data["tube"]].get
        if job
          @cache_store.reserved.set_job_reserved(job)
          if delete_on_get
            @cache_store.reserved.delete(job.id)
          end
          handler_response.add_job(JobFactory.to_hash(job))
        end
      end

      return handler_response
    end
  end
end

require "./base_handler"

# ---------------------------------
# Action: get
# Params: <none>
# ---------------------------------

module AllQ
  class GetHandler < BaseHandler
    def process(json : JSON::Any)
      handler_response = HandlerResponse.new("get")

      data = normalize_json_hash(json)
      job = @cache_store.tubes[data["tube"]].get
      if job
        @cache_store.reserved.set_job_reserved(job)
        handler_response.job = JobFactory.to_hash(job)
      else
        handler_response.job  = Hash(String, String).new
      end
      return handler_response
    end
  end
end

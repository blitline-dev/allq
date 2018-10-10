module AllQ
  class SetChildrenStartedHandler < BaseHandler
    def process(json : JSON::Any)
      data = normalize_json_hash(json)
      job_id = data["job_id"]
      @cache_store.parents.children_started!(job_id)
      handler_response = HandlerResponse.new("set_children_started")
      handler_response.job_id = job_id
      return handler_response
    end
  end
end

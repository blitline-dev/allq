module AllQ
  class SetChildrenStartedHandler < BaseHandler
    # This is called to identify that ALL children jobs have
    # been started. This is for the circumstance where you
    # don't know 'how many' children there will be, but from
    # "HERE", all the children have been submitted and that the
    # parent should start when all the submitted children have
    # completed.
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

module AllQ
  class SetChildrenStartedHandler < BaseHandler

    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      job_id = data["job_id"]
      @cache_store.parents.children_started!(job_id)
      return return_data
    end

  end
end
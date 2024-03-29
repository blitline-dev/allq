require "./base_handler"

# ---------------------------------
# Action: peek
# Params:
#     tube : <tube name> (kick job from tube into ready)
#     buried : true (Check in buried for tube)
# ---------------------------------

module AllQ
  class PeekHandler < BaseHandler
    def process(json : JSON::Any)
      handler_response = HandlerResponse.new("get")

      data = normalize_json_hash(json)
      if data["buried"]? && data["buried"]?.to_s == "true"
        job = @cache_store.buried.peek(data["tube"])
      else
        job = @cache_store.tubes[data["tube"]].peek
      end
      # if data["all_reserved"]? && data["all_reserved"]?.to_s == "true"
      #   reserved = @cache_store.reserved
      #   jobs = reserved.get_all_jobs
      #   jobs.each do |r_job|
      #     real_job = r_job.job
      #     if !real_job.nil?
      #       return_data[real_job.id] = JobFactory.to_hash(real_job)
      #       return return_data
      #     end
      #   end
      # end
      if job
        handler_response.job = JobFactory.to_hash(job)
      else
        handler_response.job = Hash(String, String).new
      end
      return handler_response
    end
  end
end

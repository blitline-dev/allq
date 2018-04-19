require "./base_handler"

# ---------------------------------
# Action: peek
# Params:
#     tube : <tube name> (kick job from tube into ready)
#     buried : true (Check in buried for tube)
# ---------------------------------

module AllQ
  class PeekHandler < BaseHandler
    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      if data["buried"]? && data["buried"]?.to_s == "true"
        job = @cache_store.buried.peek(data["tube"])
      else
        job = @cache_store.tubes[data["tube"]].peek
      end
      if job
        return_data["job"] = JobFactory.to_hash(job)
      else
        puts "No jobs for peek..."
        return_data["job"] = Hash(String, String).new
      end
      return return_data
    end
  end
end

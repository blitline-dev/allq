module AllQ
  class PutHandler < BaseHandler

    def process(json : Hash(String, JSON::Type))
      return_data = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)

      job = AllQ::Job.new(data, data["tube"])
      job.id = Random::Secure.urlsafe_base64(16)
      tube_name = data["tube"]

      priority = data["priority"]? ? data["priority"] : 5
      delay = data["delay"]? ?  data["delay"] : 0

      puts "+++++++ #{delay}"
      @cache_store.tubes[tube_name].put(job, priority.to_i, delay)
      result = Hash(String, String).new
      result["job_id"] = job.id
      return_data["job"] = result
      return return_data
    end
  end
end
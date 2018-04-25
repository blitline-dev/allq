module AllQ
  class BaseHandler
    def initialize(@cache_store : CacheStore)
      @debug = false
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
    end

    def json_to_string_hash(json_type : JSON::Any) : Hash(String, String)
      h = Hash(String, String).new
      temp_hash = json_type.as_h
      temp_hash.each do |k, v|
        h[k.to_s] = v.to_s
      end
      return h
    end

    def normalize_json_hash(json_hash : JSON::Type)
      h = Hash(String, String).new
      json_hash.each do |k, v|
        h[k.to_s] = v.to_s
      end
      return h
    end
  end
end

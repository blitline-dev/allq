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

    def normalize_json_hash(json_hash : JSON::Any)
      h = Hash(String, String).new
      json_hash.as_h.each do |k, v|
        h[k.to_s] = v.to_s
      end
      return h
    end

    def fair_queue_from_put_shard(name, shard_key)
      @cache_store.fair_queue.tube_name_from_shard_key(name, shard_key, @cache_store.tubes.all)
    end
  end
end

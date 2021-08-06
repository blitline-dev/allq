module AllQ
  class StatsHandler < BaseHandler
    def process(json : JSON::Any) : Hash(String, Hash(String, String))
      all_tubes = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      @cache_store.tubes.all.each do |tube|
        data_hash = Hash(String, String).new
        all_tubes[tube.name] = data_hash
        data_hash["ready"] = tube.size.to_s
        data_hash["delayed"] = tube.delayed_size.to_s
        data_hash["reserved"] = "0"
        data_hash["buried"] = "0"
        data_hash["parents"] = "0"
        data_hash["avg"] = GuageStats.get_avg(tube.name).to_s
        throttle_size = tube.throttle_size
        if throttle_size
          data_hash["throttle_size"] = throttle_size.to_s
        end
      end
      add(all_tubes, "reserved", @cache_store.reserved.reserved_jobs_by_tube)
      add(all_tubes, "buried", @cache_store.buried.buried_jobs_by_tube)
      add(all_tubes, "parents", @cache_store.parents.parent_jobs_by_tube)
      return all_tubes
    end

    def add(all_tubes, name, hash : Hash(String, Int32))
      hash.each do |k, v|
        tube = all_tubes[k]?
        data_hash = Hash(String, String).new
        data_hash[name] = v.to_s
        if tube
          tube.merge!(data_hash)
        else
          tube = data_hash
        end
      end
    end
  end
end

module AllQ
  class StatsHandler < BaseHandler

    def process(json : Hash(String, JSON::Type))
      all_tubes = Hash(String, Hash(String, String)).new
      data = normalize_json_hash(json)
      @cache_store.tubes.all.each do |tube|
        data_hash = Hash(String, String).new
        all_tubes[tube.name] = data_hash
        data_hash["ready"] = tube.size.to_s
        data_hash["delayed"] = tube.delayed_size.to_s
        data_hash["reserved"] = "0"
        data_hash["buried"] = "0"
      end
      add_reserved(all_tubes)
      add_buried(all_tubes)
      return all_tubes
    end

    def add_reserved(all_tubes)
      reserves = @cache_store.reserved.reserved_jobs_by_tube
      reserves.each do |k, v|
        tube = all_tubes[k]?
        data_hash = Hash(String, String).new
        data_hash["reserved"] = v.to_s
        if tube
          tube.merge!(data_hash)
        else
          tube = data_hash
        end
      end
    end

    def add_buried(all_tubes)
      reserves = @cache_store.buried.buried_jobs_by_tube
      reserves.each do |k, v|
        tube = all_tubes[k]?
        data_hash = Hash(String, String).new
        data_hash["buried"] = v.to_s
        if tube
          tube.merge!(data_hash)
        else
          tube = data_hash
        end
      end
    end

  end
end
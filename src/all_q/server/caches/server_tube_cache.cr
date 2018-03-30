module AllQ
  class ServerTubeCache

    def initialize
      @cache = Hash(String, AllQ::Tube).new
    end

    def reserved_cache
      return @reserved_cache
    end

    def buried_cache
      return @buried_cache
    end
    
    def all
      @cache.values
    end

    def [](key)
      get(key)
    end

    def get(name)
      tube = @cache[name]?
      if tube.nil?
        tube = AllQ::Tube.new(name)
        @cache[name] = tube
      end
      return tube
    end

    def put(job, priority = 5, delay = 0)
      tube = get(job.tube)
      tube.put(job, priority, delay)
    end



  end
end
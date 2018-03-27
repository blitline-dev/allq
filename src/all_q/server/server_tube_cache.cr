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



  end
end
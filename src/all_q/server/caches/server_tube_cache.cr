require "file_utils"

module AllQ
  class ServerTubeCache
    def initialize
      @cache = Hash(String, AllQ::Tube).new
      prep_serializers
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

    # --------------------------------------------
    # Serializer Init
    # --------------------------------------------
    def prep_serializers
      @base_dir = ENV["SERIALIZER_DIR"]? || "/tmp"
      ensure_dirs
      prep_tubes
    end

    def ensure_dirs
      FileUtils.mkdir_p("#{@base_dir}/buried")
      FileUtils.mkdir_p("#{@base_dir}/reserved")
      FileUtils.mkdir_p("#{@base_dir}/parents")
      FileUtils.mkdir_p("#{@base_dir}/ready")
      FileUtils.mkdir_p("#{@base_dir}/delayed")
    end

    def prep_tubes
      tubes = Array(String).new
      tubes += Dir.glob("#{@base_dir}/ready/*").reject { |e| !File.directory?(e) }
      tubes += Dir.glob("#{@base_dir}/delayed/*").reject { |e| !File.directory?(e) }
      tubes.map! { |t| t.split('/').last }
      tubes.uniq!
      tubes.each do |tube|
        tube = get(tube)
        tube.load_serialized
      end
    end
  end
end

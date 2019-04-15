require "file_utils"

module AllQ
  class ServerTubeCache
    def initialize
      @cache = Hash(String, AllQ::Tube).new
      prep_serializers
      start_sweeper
      @debug = false
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
    end

    def clear_all
      @cache.clear
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
      puts "Adding to tube #{job.id} #{priority} #{delay}" if @debug
      tube.put(job, priority, delay)
    end

    def start_sweeper
      spawn do
        loop do
          begin
            puts "Sweeping for dead tubes..."
            time_now = Time.now
            @cache.delete_if do |key, value|
              value.size == 0 && value.touched < time_now - 1.hour
            end
          rescue ex
            puts "Server Tube Cache Sweeper Exception"
            puts ex.inspect_with_backtrace
          end
          sleep(3600)
        end
      end
    end

    # --------------------------------------------
    # Serializer Init
    # --------------------------------------------
    def prep_serializers
      @base_dir = EnvConstants::SERIALIZER_DIR
      return unless (ENV["SERIALIZE"]?.to_s == "true")

      ensure_dirs
      prep_tubes
    end

    def ensure_dirs
      FileUtils.mkdir_p("#{@base_dir}/buried", File::Permissions::All.to_i)
      FileUtils.mkdir_p("#{@base_dir}/reserved", File::Permissions::All.to_i)
      FileUtils.mkdir_p("#{@base_dir}/parents", File::Permissions::All.to_i)
      FileUtils.mkdir_p("#{@base_dir}/ready", File::Permissions::All.to_i)
      FileUtils.mkdir_p("#{@base_dir}/delayed", File::Permissions::All.to_i)
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

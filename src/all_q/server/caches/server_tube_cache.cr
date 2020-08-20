require "file_utils"

module AllQ
  class ServerTubeCache
    def initialize
      @expire_hours = ENV["ALLQ_TUBE_EXPIRE_HOURS"]? ? ENV["ALLQ_TUBE_EXPIRE_HOURS"].to_i : 1
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
            time_now = Time.utc
            @cache.delete_if do |key, value|
              value.size == 0 && value.touched < time_now - @expire_hours.hour && value.throttle_size.nil?
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

    def delete_tube_folders(tube)
      begin
        delete_if_exists("#{@base_dir}/buried/#{tube}")
        delete_if_exists("#{@base_dir}/reserved/#{tube}")
        delete_if_exists("#{@base_dir}/parents/#{tube}")
        delete_if_exists("#{@base_dir}/ready/#{tube}")
        delete_if_exists("#{@base_dir}/delayed/#{tube}")
      rescue ex
        puts ex.message
        puts ex.inspect_with_backtrace
      end
    end

    def size_if_exists(path)
      Dir.exists?(path) ? Dir.children(path).size : 0
    end

    def delete_if_exists(path)
      Dir.delete(path) if Dir.exists?(path)
    end

    def count_for_all_folders(tube)
      count = 0
      count += size_if_exists("#{@base_dir}/buried/#{tube}")
      count += size_if_exists("#{@base_dir}/reserved/#{tube}")
      count += size_if_exists("#{@base_dir}/parents/#{tube}")
      count += size_if_exists("#{@base_dir}/ready/#{tube}")
      count += size_if_exists("#{@base_dir}/delayed/#{tube}")
      return count
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
      tubes.select! do |tube|
        count = count_for_all_folders(tube)
        if count > 0
          tube = get(tube)
          tube.load_serialized
          true
        else
          # All empty, so delete
          # We don't want these showing up
          # on restart
          delete_tube_folders(tube)
          false
        end
      end
    end
  end
end

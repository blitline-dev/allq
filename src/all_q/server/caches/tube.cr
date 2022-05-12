module AllQ
  class Tube
    property :name, :priority_queue, :delayed, :touched
    PRIORITY_SIZE  = ENV["PRIORITY_SIZE"]? || 10
    DURATION_LIMIT = ENV["DURATION_LIMIT"]? || 30

    property action : String | Nil = nil
    property throttle : ThrottleInstance

    def initialize(@name : String)
      @priority_queue = PriorityQueue(Job).new(PRIORITY_SIZE.to_i)
      @delayed = Array(DelayedJob).new
      @ready_serde = ReadyCacheSerDe(Job).new(@name)
      @delayed_serde = DelayedCacheSerDe(DelayedJob).new(@name)
      @throttle_serde = ThrottleSerDe(String).new(@name)
      @touched = Time.utc
      @paused = false
      @debug = false
      @durations = Array(Int32).new
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
      touch
      start_sweeper
    end

    def delete_job(job_id)
      # This should be a RARE occurance. This is an expensive
      @priority_queue.delete_if_exists(job_id)
    end

    def pause(paused : Bool)
      @paused = paused
    end

    def clear
      # Delete ready
      job = get
      while job
        delete_job(job.id)
        job = get
      end
      # Delete delayed
      @delayed.clear
      @ready_serde.empty_folder
      @delayed_serde.empty_folder
    end

    def touch
      @touched = Time.utc
    end

    def load_serialized
      @ready_serde.load_special(@priority_queue)
      @delayed_serde.load_special(@delayed)
      throttle_val = @throttle_serde.load
      unless throttle_val.nil?
        puts "Throttle for #{@name} set to #{throttle_val}"
        set_throttle(throttle_val)
      end
    end

    def set_throttle(per_second : Int32)
      if per_second <= 0
        @throttle = nil
        puts "Setting throttle to OFF"
        @throttle_serde.remove
      else
        @throttle = AllQ::Throttle.new(per_second)
        @throttle_serde.serialize(per_second)
      end
    end

    def put(job, priority = 5, delay : Int32 = 0)
      touch
      puts "tube: #{@name}: Adding to tube #{job.id} priority: #{priority} delay: #{delay}" if @debug

      if delay < 1
        job.created_time = Time.utc.to_unix
        @priority_queue.put(job, priority)
        @ready_serde.serialize(job)
      else
        time_to_start = Time.utc.to_unix + delay
        delayed_job = DelayedJob.new(time_to_start, job, priority)
        @delayed << delayed_job
        @delayed_serde.serialize(delayed_job)
      end
    end

    def peek
      @priority_queue.peek
    end

    def get
      touch
      return nil if @paused
      continue = true
      throttle = @throttle
      if throttle
        continue = throttle.check_and_add?
      end
      if continue
        job = @priority_queue.get
        if job
          job.reserved = true
          @ready_serde.remove(job)
        end
      else
        return nil
      end
      return job
    end

    def throttle_size
      throttle = @throttle
      if throttle
        return throttle.size
      end
      return nil
    end

    def size
      @priority_queue.size
    end

    def delayed_size
      @delayed.size
    end

    def start_sweeper
      spawn do
        loop do
          begin
            time_now = Time.utc.to_unix
            @delayed.reject! do |delayed_job|
              if delayed_job.time_to_start < time_now
                put(delayed_job.job, delayed_job.priority)
                @delayed_serde.remove(delayed_job.job)
                true
              else
                false
              end
            end
            sleep(1)
          rescue ex
            puts "Tube start_sweeper Exception"
            puts ex.inspect_with_backtrace
          end
        end
      end
    end

    struct DelayedJob
      include JSON::Serializable
      property time_to_start, job, priority

      def initialize(@time_to_start : Int64, @job : Job, @priority : Int32)
      end
    end
  end

  # ----------------------------------------
  # Serializer
  # ----------------------------------------

  class ThrottleSerDe(T) < BaseSerDe(T)
    def initialize(@name : String)
      return unless SERIALIZE
      @base_dir = EnvConstants::SERIALIZER_DIR
      FileUtils.mkdir_p("#{@base_dir}/throttles/", File::Permissions::All.to_i)
    end

    def serialize(throttle_value)
      return unless SERIALIZE
      file_path = build_throttle_filepath(@name)
      if throttle_value.to_i < 0
        remove
        return
      end
      File.open(file_path, "w") do |f|
        f.puts(throttle_value.to_s)
      end
    end

    def remove
      return unless SERIALIZE
      FileWrapper.rm(build_throttle_filepath(@name))
    end

    def load
      return unless SERIALIZE
      return nil unless File.exists?(build_throttle_filepath(@name))
      File.read(build_throttle_filepath(@name)).strip.to_i
    end
  end

  # ----------------------------------------
  # Serializer
  # ----------------------------------------

  class ReadyCacheSerDe(T) < BaseSerDe(T)
    def initialize(@name : String)
      return unless SERIALIZE
      @base_dir = EnvConstants::SERIALIZER_DIR
      FileUtils.mkdir_p("#{@base_dir}/ready/#{@name}", File::Permissions::All.to_i)
    end

    def serialize(ready_job : T)
      return unless SERIALIZE
      file_path = build_ready(ready_job)
      File.open(file_path, "w") do |f|
        Cannon.encode f, ready_job
      end
    end

    def empty_folder
      return unless SERIALIZE
      folder = build_ready_folder(@name)
      FileUtils.rm_rf("#{folder}/.")
    end

    def remove(job : Job)
      return unless SERIALIZE
      filepath = build_ready(job)
      FileUtils.rm(filepath) if File.exists?(filepath)
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
      load_special
    end

    def load_special(priority_queue : PriorityQueue(Job))
      return unless SERIALIZE
      base_path = "#{@base_dir}/ready/#{@name}/*"
      Dir[base_path].each do |file|
        job = Cannon.decode_to_job? file
        if job
          remove(job)
          priority_queue.put(job, job.priority)
        end
      end
    end
  end

  # ----------------------------------------
  # Serializer
  # ----------------------------------------

  class DelayedCacheSerDe(T) < BaseSerDe(T)
    def initialize(@name : String)
      return unless SERIALIZE

      @base_dir = EnvConstants::SERIALIZER_DIR
      FileUtils.mkdir_p("#{@base_dir}/delayed/#{@name}", File::Permissions::All.to_i)
    end

    def serialize(delayed : T)
      return unless SERIALIZE
      file_path = build_delayed(delayed.job)

      File.open(file_path, "w") do |f|
        Cannon.encode f, delayed
      end
    end

    def empty_folder
      return unless SERIALIZE
      folder = build_delayed_folder(@name)
      FileUtils.rm_rf("#{folder}/.")
    end

    def remove(job : Job)
      return unless SERIALIZE
      filepath = build_delayed(job)
      AllQ::FileWrapper.rm(filepath) if File.exists?(filepath)
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
    end

    def load_special(cache : Array(AllQ::Tube::DelayedJob))
      return unless SERIALIZE
      base_path = "#{@base_dir}/delayed/#{@name}/*"
      Dir[base_path].each do |file|
        begin
          job = Cannon.decode_to_delayed_job file
          if job
            cache << job
          end
        rescue ex
          puts "Failed to load #{file}, #{{ex.message}}"
          AllQ::FileWrapper.rm(file) if File.exists?(file)
        end
      end
    end
  end
end

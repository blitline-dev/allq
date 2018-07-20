module AllQ
  class Tube
    property :name, :priority_queue, :delayed, :touched
    PRIORITY_SIZE = ENV["PRIORITY_SIZE"]? || 10

    def initialize(@name : String)
      @priority_queue = PriorityQueue(Job).new(PRIORITY_SIZE.to_i)
      @delayed = Array(DelayedJob).new
      @ready_serde = ReadyCacheSerDe(Job).new(@name)
      @delayed_serde = DelayedCacheSerDe(DelayedJob).new(@name)
      @touched = Time.now
      @paused = false
      touch
      start_sweeper
    end

    def pause(paused : Bool)
      @paused = paused
    end

    def clear
      @priority_queue.clear
      @delayed.clear
    end

    def touch
      @touched = Time.now
    end

    def load_serialized
      @ready_serde.load_special(@priority_queue)
      @delayed_serde.load_special(@delayed)
    end

    def set_throttle(per_second : Int32)
      @throttle = AllQ::Throttle.new(per_second)
    end

    def put(job, priority = 5, delay = 0)
      touch
      if delay.to_i < 1
        @priority_queue.put(job, priority)
        @ready_serde.serialize(job)
      else
        time_to_start = Time.now.to_s("%s").to_i + delay.to_i
        @delayed << DelayedJob.new(time_to_start, job, priority)
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
          @ready_serde.move_ready_to_reserved(job)
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
            time_now = Time.now.to_s("%s").to_i
            @delayed.reject! do |delayed_job|
              if delayed_job.time_to_start < time_now
                put(delayed_job.job, delayed_job.priority)
                @ready_serde.move_delayed_to_ready(delayed_job.job)
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
      include Cannon::Auto
      property time_to_start, job, priority

      def initialize(@time_to_start : Int32, @job : Job, @priority : Int32)
      end
    end
  end

  # ----------------------------------------
  # Serializer
  # ----------------------------------------

  class ReadyCacheSerDe(T) < BaseSerDe(T)
    def initialize(@name : String)
      return unless SERIALIZE
      @base_dir = ENV["SERIALIZER_DIR"]? || "/tmp"
      FileUtils.mkdir_p("#{@base_dir}/ready/#{@name}")
    end

    def move_ready_to_reserved(job : Job)
      return unless SERIALIZE
      ready = build_ready(job)
      reserved = build_reserved(job)
      FileUtils.mv(ready, reserved)
    end

    def move_delayed_to_ready(job : Job)
      return unless SERIALIZE
      delayed = build_delayed(job)
      ready = build_ready(job)
      FileUtils.mv(delayed, ready)
    end

    def serialize(ready_job : T)
      return unless SERIALIZE
      file_path = build_ready(ready_job)
      File.open(file_path, "w") do |f|
        Cannon.encode f, ready_job
      end
    end

    def remove(job : Job)
      return unless SERIALIZE
      FileUtils.rm(build_ready(job))
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
      load_special
    end

    def load_special(priority_queue : PriorityQueue(Job))
      return unless SERIALIZE
      base_path = "#{@base_dir}/ready/#{@name}/*"
      Dir[base_path].each do |file|
        File.open(file, "r") do |f|
          puts file
          job = Cannon.decode f, Job
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

      @base_dir = ENV["SERIALIZER_DIR"]? || "/tmp"
      FileUtils.mkdir_p("#{@base_dir}/delayed/#{@name}")
    end

    def serialize(delayed : T)
      return unless SERIALIZE
      file_path = build_delayed(delayed)
      File.open(file_path, "w") do |f|
        Cannon.encode f, delayed
      end
    end

    def remove(job : Job)
      return unless SERIALIZE
      FileUtils.rm(build_delayed(job))
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
    end

    def load_special(cache : Array(AllQ::Tube::DelayedJob))
      return unless SERIALIZE
      base_path = "#{@base_dir}/delayed/#{@name}/*"
      Dir[base_path].each do |file|
        begin
          File.open(file, "r") do |f|
            puts file
            job = Cannon.decode f, T
            cache << job
          end
        rescue ex
          puts "Failed to load #{file}, #{{ex.message}}"
          FileUtils.rm(file) if File.exists?(file)
        end
      end
    end
  end
end

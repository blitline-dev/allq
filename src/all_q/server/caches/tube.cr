module AllQ
  class Tube
    property :name, :priority_queue, :delayed
    PRIORITY_SIZE = ENV["PRIORITY_SIZE"]? || 10

    def initialize(@name : String)
      @priority_queue = PriorityQueue(Job).new(PRIORITY_SIZE.to_i)
      @delayed = Array(DelayedJob).new
      @ready_serde = ReadyCacheSerDe(Job).new(@name)
      @delayed_serde = DelayedCacheSerDe(DelayedJob).new(@name)
    end

    def load_serialized
      @ready_serde.load_special(@priority_queue)
      @delayed_serde.load_special(@delayed)
    end

    def set_throttle(per_second : Int32)
      @throttle = AllQ::Throttle.new(per_second)
    end

    def put(job, priority = 5, delay = 0)
      if delay == 0
        @priority_queue.put(job, priority)
        @ready_serde.serialize(job)
      else
        time_to_start = Time.now.to_s("%s").to_i + delay.to_i
        @delayed << DelayedJob.new(time_to_start, job, priority)
      end
    end

    def get
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
      @base_dir = ENV["SERIALIZER_DIR"]? || "/tmp"
      FileUtils.mkdir_p("#{@base_dir}/ready/#{@name}")
    end

    def move_ready_to_reserved(job : Job)
      ready = build_ready(job)
      reserved = build_reserved(job)
      FileUtils.mv(ready, reserved)
    end

    def move_delayed_to_ready(job : Job)
      delayed = build_delayed(job)
      ready = build_ready(job)
      FileUtils.mv(delayed, ready)
    end

    def serialize(ready_job : T)
      file_path = build_ready(ready_job)
      File.open(file_path, "w") do |f|
        Cannon.encode f, ready_job
      end
    end

    def remove(job : Job)
      FileUtils.rm(build_ready(job))
    end

    def load(cache : Hash(String, T))
      load_special
    end

    def load_special(priority_queue : PriorityQueue(Job))
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
      @base_dir = ENV["SERIALIZER_DIR"]? || "/tmp"
      FileUtils.mkdir_p("#{@base_dir}/delayed/#{@name}")
    end

    def serialize(delayed : T)
      file_path = build_delayed(delayed)
      File.open(file_path, "w") do |f|
        Cannon.encode f, delayed
      end
    end

    def remove(job : Job)
      FileUtils.rm(build_delayed(job))
    end

    def load(cache : Hash(String, T))
    end

    def load_special(cache : Array(AllQ::Tube::DelayedJob))
      base_path = "#{@base_dir}/delayed/#{@name}/*"
      Dir[base_path].each do |file|
        File.open(file, "r") do |f|
          puts file
          job = Cannon.decode f, T
          cache << job
        end
      end
    end
  end
end
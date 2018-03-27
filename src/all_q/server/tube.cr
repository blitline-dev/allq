
module AllQ
  class Tube
    property :name
    def initialize(@name : String)
      @priority_queue = PriorityQueue(AllQ::Job).new(10)
      @delayed = Array(DelayedJob).new
      start_sweeper
    end

    def put(job, priority = 5, delay = 0)
      if delay == 0
        @priority_queue.put(job, priority)
      else
        time_to_start = Time.now.to_s("%s").to_i + delay.to_i
        @delayed << DelayedJob.new(time_to_start, job, priority)
      end
    end

    def get
      job = @priority_queue.get
      if job
        job.reserved = true
      end
      return job
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
      property time_to_start, job, priority

      def initialize(@time_to_start : Int32, @job : Job, @priority : Int32)
      end
    end

  end
end

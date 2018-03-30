require "json"

module AllQ
  class ParentCache
    def initialize(tube_cache : ServerTubeCache, buried_cache : AllQ::BuriedCache)
      @cache = Hash(String, ParentJob).new
      @tubes = tube_cache
      @buried = buried_cache
    end

    def set_job_as_parent(job : AllQ::Job, timeout : Int32, run_on_timeout = false)
      now = Time.now.to_s("%s").to_i
      parent_job = ParentJob.new(now, job, 0, timeout, run_on_timeout)
      @cache[job.id] = parent_job
    end

    def child_started(job_id)
      parent_job = get(job_id)
      parent_job.increment_started
      check_parent_job(job_id)
    end

    def child_completed(job_id)
      check_parent_job(job_id, true)
    end

    def children_started!(job_id)
      parent_job = get(job_id)
      parent_job.set_limit!
      check_parent_job(job_id)
    end

    def set_limit(job_id : String, limit : Int32)
      parent_job = @cache.fetch(job_id)
      parent_job.limit = limit
      check_parent_job(job_id)
    end

    def get(job_id)
      parent_job = @cache.fetch(job_id)
      return parent_job
    end

    def check_parent_job(job_id, increment_child_count = false)
      parent_job = @cache.fetch(job_id)
      parent_job.child_count += 1 if increment_child_count
      if parent_job.limit > 0
        if parent_job.limit <= parent_job.child_count
          start_parent_job(parent_job)
        end
      end
    end

    def start_parent_job(parent_job)
      job = parent_job.job
      @cache.delete(job.id)
      if job.noop
        new_parent_job = get(job.parent_id)
        start_parent_job(new_parent_job)
        return
      end
      @tubes.put(job)
    end

    def start_sweeper
      spawn do
        loop do
          sweep
          sleep(5)
        end
      end
    end

    def sweep
      now = Time.now.to_s("%s").to_i
      @cache.values.each do |parent_job|
        if parent_job.start + parent_job.timeout < now
          if parent_job.run_on_timeout
            start_parent_job(parent_job)
          else
            @cach.delete(parent_job.job.id)
            @buried.set_job_buried(parent_job.job)
          end
        end
      end
    end

    class ParentJob
      property :start, :job, :child_count, :timeout, :limit, :run_on_timeout, :started_count

      def initialize(@start : Int32, @job : Job, @child_count : Int32, @timeout : Int32, @run_on_timeout : Bool)
        @started_count = 0
        @limit = 0
      end

      def set_limit(limit)
        @limit = limit
      end

      def set_limit!
        @limit = started_count
      end

      def increment_started
        @started_count += 1
      end

    end
  end
end
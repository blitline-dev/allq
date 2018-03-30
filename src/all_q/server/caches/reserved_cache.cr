module AllQ
  class ReservedCache

    def initialize(tube_cache : AllQ::ServerTubeCache, buried_cache : AllQ::BuriedCache, parent_cache : AllQ::ParentCache)
      @cache = Hash(String, ReservedJob).new
      @tube_cache = tube_cache
      @buried_cache = buried_cache
      @parent_cache = parent_cache
      start_sweeper
    end

    def set_job_reserved(job : AllQ::Job)
      now = Time.now.to_s("%s").to_i
      @cache[job.id] = ReservedJob.new(now, job)
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
      @cache.values.each do |reserved_job|
        if reserved_job.start + reserved_job.job.ttl < now
          expire_job(reserved_job)
        end
      end
    end

    def get_job_ids
      @cache.keys
    end

    def expire_job(reserved_job)
      job = reserved_job.job
      job.expired_count += 1
      job.reserved = false
      if job.expired_count > job.expired_limit
        @buried_cache.set_job_buried(job)
        @cache.delete(job.id)
        return
      end

      tube = @tube_cache[job.tube]
      tube.put(job)
      @cache.delete(job.id)
    end

    def delete(job_id)
      if @cache[job_id]?
        @cache.delete(job_id) 
      end
    end

    def done(job_id)
      delete(job_id)
      if @cache[job_id]?
        reserved_job = @cache[job_id]
        parent_job_id = reserved_job.job.parent_id
        if parent_job_id
          @parent_cache.child_completed(parent_job_id)
        end
      end
    end


    def touch(job_id)
      reserved_job = @cache[job_id]?
      if reserved_job
        reserved_job.start = Time.now.to_s("%s").to_i
      end
      return job_id
    end

    def reserved_jobs_by_tube
      tubes = Hash(String, Int32).new
      @cache.each do |k, v|
        tubes[v.job.tube] = 0 unless tubes[v.job.tube]?
        tubes[v.job.tube] += 1
      end
      return tubes
    end


    struct ReservedJob
      property start, job

      def initialize(@start : Int32, @job : Job)
      end
    end
  end

end
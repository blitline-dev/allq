module AllQ
  class BuriedCache

    def initialize(tube_cache : ServerTubeCache)
      @cache = Hash(String, Job).new
      @tube_cache = tube_cache
    end

    def set_job_buried(job : AllQ::Job)
      @cache[job.id] = job
    end

    def get_job_ids
      @cache.keys
    end

    def delete(job_id)
      @cache.delete[job_id] if @cache[job_id]
    end

    def kick(job_id)
      job = @cache[job_id]?
      if job
        @tube_cache[job.tube].put(job)
      end
    end

    def buried_jobs_by_tube
      tubes = Hash(String, Int32).new
      @cache.each do |k, v|
        tubes[v.job.tube] = 0 unless tubes[v.job.tube]?
        tubes[v.job.tube] += 1
      end
      return tubes
    end

  end
end
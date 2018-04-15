module AllQ
  class ReservedCache
    def initialize(tube_cache : AllQ::ServerTubeCache, buried_cache : AllQ::BuriedCache, parent_cache : AllQ::ParentCache)
      @cache = Hash(String, ReservedJob).new
      @tube_cache = tube_cache
      @buried_cache = buried_cache
      @parent_cache = parent_cache
      @serializer = ReservedCacheSerDe(ReservedJob).new
      @serializer.load(@cache)
      start_sweeper
    end

    def clear_all
      @cache.clear
    end

    def set_job_reserved(job : Job)
      now = Time.now.to_s("%s").to_i
      @cache[job.id] = ReservedJob.new(now, job)
      @serializer.serialize(@cache[job.id])
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
        delete(job.id)
        @serializer.move_reserved_to_buried(job)
        return
      end

      tube = @tube_cache[job.tube]
      tube.put(job)
      @serializer.move_reserved_to_ready(job)
      delete(job.id)
    end

    def delete(job_id)
      if @cache[job_id]?
        job = @cache[job_id]
        @serializer.remove(job.job)
        @cache.delete(job_id)
        return job.job
      end
      return nil
    end

    def done(job_id)
      if @cache[job_id]?
        reserved_job = @cache[job_id]
        parent_job_id = reserved_job.job.parent_id
        if !parent_job_id.to_s.blank?
          @parent_cache.child_completed(parent_job_id)
        end
        job = @cache[job_id].job
        delete(job_id)
        return job
      end
      return nil
    end

    def release(job_id)
      reserverd_job = @cache[job_id]?
      if reserverd_job
        job = reserverd_job.job
        tube = @tube_cache[job.tube]
        tube.put(job)
        @serializer.move_reserved_to_ready(job)
        @cache.delete(job_id)
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
      include Cannon::Auto

      property start, job

      def initialize(@start : Int32, @job : Job)
      end
    end
  end

  # ----------------------------------------
  # Serializer
  # ----------------------------------------

  class ReservedCacheSerDe(T) < BaseSerDe(T)
    def serialize(reserved_job : T)
      return unless SERIALIZE

      File.open(build_reserved(reserved_job.job), "w") do |f|
        Cannon.encode f, reserved_job
      end
    end

    def move_reserved_to_ready(job : Job)
      return unless SERIALIZE
      reserved = build_reserved(job)
      ready = build_ready(job)
      FileUtils.mv(reserved, ready)
    end

    def move_reserved_to_buried(job : Job)
      return unless SERIALIZE
      reserved = build_reserved(job)
      buried = build_buried(job)
      FileUtils.mv(reserved, buried)
    end

    def remove(job : Job)
      return unless SERIALIZE
      FileUtils.rm(build_reserved(job))
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
      base_path = "#{@base_dir}/reserved/*"
      Dir[base_path].each do |file|
        File.open(file, "r") do |f|
          puts file
          job = Cannon.decode f, ReservedCache::ReservedJob
          cache[job.job.id] = job
        end
      end
    end
  end
end

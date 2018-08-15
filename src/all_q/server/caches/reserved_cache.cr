module AllQ
  class ReservedCache
    def initialize(tube_cache : AllQ::ServerTubeCache, buried_cache : AllQ::BuriedCache, parent_cache : AllQ::ParentCache)
      @cache = Hash(String, ReservedJob).new
      @tube_cache = tube_cache
      @buried_cache = buried_cache
      @parent_cache = parent_cache
      @serializer = ReservedCacheSerDe(ReservedJob).new
      @serializer.load(@cache)
      @debug = false
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
      start_sweeper
    end

    def get_all_jobs
      return @cache.values
    end

    def clear_all
      @cache.clear
    end

    def set_job_reserved(job : Job)
      now = Time.now.to_s("%s").to_i
      @cache[job.id] = ReservedJob.new(now, job)
      @serializer.serialize(@cache[job.id])
      puts "Time in ready(#{Time.now.epoch_ms - job.created_time})" if @debug
    end

    def start_sweeper
      spawn do
        loop do
          begin
            sweep
          rescue ex
            puts ex.inspect_with_backtrace
          end
          sleep(5)
        end
      end
    end

    def sweep
      puts "Sweeping Reservered Cache" if @debug
      now = Time.now.to_s("%s").to_i
      @cache.values.each do |reserved_job|
        if reserved_job.start + reserved_job.job.ttl < now
          puts "Expiring Job From Reserved Cache" if @debug
          expire_job(reserved_job)
        end
      end
    end

    def get_job_ids
      @cache.keys
    end

    def expire_job(reserved_job)
      job = reserved_job.job
      job.expireds += 1
      job.reserved = false

      if job.expireds > job.expired_limit
        puts "Burying job -> #{job.id}" if @debug
        @buried_cache.set_job_buried(job)
        @serializer.move_reserved_to_buried(job)
        delete(job.id)
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

    def bury(job_id)
      if @cache[job_id]?
        job = @cache[job_id].job
        @buried_cache.set_job_buried(job)
        @serializer.move_reserved_to_buried(job)
        delete(job.id)
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

    def release(job_id, delay : Int32 = 0)
      reserverd_job = @cache[job_id]?
      if reserverd_job
        job = reserverd_job.job
        tube = @tube_cache[job.tube]
        tube.put(job, job.priority, delay)
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
      include JSON::Serializable
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
      AllQ::FileWrapper.mv(reserved, ready)
    end

    def move_reserved_to_buried(job : Job)
      return unless SERIALIZE
      reserved = build_reserved(job)
      buried = build_buried(job)
      AllQ::FileWrapper.mv(reserved, buried)
    end

    def remove(job : Job)
      return unless SERIALIZE
      AllQ::FileWrapper.rm(build_reserved(job)) if File.exists?(build_reserved(job))
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
      base_path = "#{@base_dir}/reserved/*"
      Dir[base_path].each do |file|
        begin
          job = Cannon.decode_to_reserved_job file
          if job
            cache[job.job.id] = job
          end
        rescue ex
          puts "Failed to load #{file}, #{{ex.message}}"
          AllQ::FileWrapper.rm(file)
        end
      end
    end
  end
end

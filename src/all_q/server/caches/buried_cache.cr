module AllQ
  class BuriedCache
    def initialize(tube_cache : ServerTubeCache)
      @cache = Hash(String, Job).new
      @tube_cache = tube_cache
    end

    def clear_all
      @cache.clear
    end

    def set_job_buried(job : Job)
      @cache[job.id] = job
    end

    def count
      @cache.size
    end

    def get_job_ids
      @cache.keys
    end

    def delete(job_id)
      if @cache[job_id]?
        job = @cache[job_id]
        @cache.delete(job_id)
        return job
      end
      return nil
    end

    def get_buried_by_tube(tube)
      result = Array(Job).new
      @cache.each do |k, job|
        if job.tube == tube
          result << job
        end
      end
      return result
    end

    def peek(tube)
      get_burieds = get_buried_by_tube(tube)
      return get_burieds.first?
    end

    # Not sure about kick functionality
    def kick(tube)
      jobs = get_buried_by_tube(tube)
      job = jobs.shift?
      if job
        delete(job.id)
        @tube_cache[job.tube].put(job)
        return job.id
      end
      return nil
    end

    # def kick
    #   first = @cache.shift?
    #   if first
    #     job = first[1]
    #     @tube_cache[job.tube].put(job)
    #   end
    # end

    def buried_jobs_by_tube
      tubes = Hash(String, Int32).new
      @cache.each do |k, job|
        tubes[job.tube] = 0 unless tubes[job.tube]?
        tubes[job.tube] += 1
      end
      return tubes
    end
  end

  # ----------------------------------------
  # Serializer
  # ----------------------------------------

  class BuriedCacheSerDe(T) < BaseSerDe(T)
    def serialize(buried_job : T)
      return unless SERIALIZE
      File.open(build_buried(buried_job), "w") do |f|
        Cannon.encode f, buried_job
      end
    end

    def remove(job : Job)
      return unless SERIALIZE
      AllQ::FileWrapper.rm(build_buried(job))
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
      base_path = "#{@base_dir}/buried/*"
      Dir[base_path].each do |file|
        begin
          File.open(file, "r") do |f|
            puts file
            job = Cannon.decode f, Job
            cache[job.id] = job
          end
        rescue ex
          puts "Failed to load #{file}, #{{ex.message}}"
          AllQ::FileWrapper.rm(file) if File.exists?(file)
        end
      end
    end
  end
end

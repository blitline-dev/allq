require "json"

module AllQ
  class ParentCache
    def initialize(@tubes : AllQ::ServerTubeCache, @buried : AllQ::BuriedCache)
      @cache = Hash(String, ParentJob).new
      @serializer = ParentCacheSerDe(ParentJob).new
      @serializer.load(@cache)
      start_sweeper
    end

    def clear_all
      @cache.clear
    end

    def set_job_as_parent(job : Job, timeout : Int32, run_on_timeout = false)
      now = Time.now.to_s("%s").to_i
      parent_job = ParentJob.new(now, job, 0, timeout, -1, run_on_timeout, 0)
      @cache[job.id] = parent_job
      @serializer.serialize(parent_job)
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
      puts
      if parent_job.limit > 0
        if parent_job.limit <= parent_job.child_count
          start_parent_job(parent_job)
        end
      end
    end

    def parent_jobs_by_tube
      tubes = Hash(String, Int32).new
      @cache.each do |k, v|
        tubes[v.job.tube] = 0 unless tubes[v.job.tube]?
        tubes[v.job.tube] += 1
      end
      return tubes
    end

    def start_parent_job(parent_job)
      job = parent_job.job
      @cache.delete(job.id)

      if job.noop
        if !job.parent_id.to_s.blank?
          new_parent_job = get(job.parent_id).job
          child_completed(job.parent_id)
        end
        @serializer.remove(job)
        return
      end
      #  @serializer.move_from_parent_to_ready(job)
      @serializer.move_parent_to_ready(parent_job.job)
      @tubes.put(job)
    end

    def start_sweeper
      spawn do
        loop do
          begin
            sweep
            sleep(5)
          rescue ex
            puts "Parent Cache start_sweeper Exception"
            puts ex.inspect_with_backtrace
          end
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
            @cache.delete(parent_job.job.id)
            @serializer.move_parent_to_buried(parent_job.job)
            @buried.set_job_buried(parent_job.job)
          end
        end
      end
    end

    class ParentJob
      include Cannon::Auto
      property :start, :job, :child_count, :timeout, :limit, :run_on_timeout, :started_count

      def initialize(@start : Int32, @job : Job, @child_count : Int32, @timeout : Int32, @limit : Int32, @run_on_timeout : Bool, @started_count : Int32)
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

  # ----------------------------------------
  # Serializer
  # ----------------------------------------

  class ParentCacheSerDe(T) < BaseSerDe(T)
    def serialize(parent_job : T)
      return unless SERIALIZE
      File.open(build_parent(parent_job.job), "w") do |f|
        Cannon.encode f, parent_job.job
      end
    end

    def move_parent_to_ready(job : Job)
      return unless SERIALIZE
      parent = build_parent(job)
      ready = build_ready(job)
      AllQ::FileWrapper.mv(parent, ready)
    end

    def move_parent_to_buried(job : Job)
      return unless SERIALIZE
      parent = build_parent(job)
      buried = build_buried(job)
      AllQ::FileWrapper.mv(parent, buried)
    end

    def remove(job : Job)
      return unless SERIALIZE
      AllQ::FileWrapper.rm(build_parent(job))
    end

    def load(cache : Hash(String, T))
      return unless SERIALIZE
      base_path = "#{@base_dir}/parents/*"
      Dir[base_path].each do |file|
        begin
          File.open(file, "r") do |f|
            puts file
            job = Cannon.decode f, ParentCache::ParentJob
            cache[job.job.id] = job
          end
        rescue ex
          puts "Failed to load #{file}, #{{ex.message}}"
          AllQ::FileWrapper.rm(file) if File.exists?(file)
        end
      end
    end
  end
end

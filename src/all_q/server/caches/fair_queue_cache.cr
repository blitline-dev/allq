require "digest"

module AllQ
  class FairQueueCache
    SHARD_COUNT        = (ENV["FQ_SHARD_COUNT"]? || 10).to_i
    ENV_FQ_PREFIX      = (ENV["FQ_PREFIX"]? || "fq-")
    ENV_FQ_PREFIX_SIZE = ENV_FQ_PREFIX.size
    ENV_FQ_SUFFIX      = ENV["FQ_SUFFIX"]?
    ENV_FQ_SUFFIX_SIZE = ENV_FQ_SUFFIX.to_s.size

    def initialize
      @name_to_index = Hash(String, Int32).new
    end

    def is_fair_queue(name : String)
      if ENV_FQ_SUFFIX
        return false if name.size <= ENV_FQ_SUFFIX_SIZE
        return name[-ENV_FQ_SUFFIX_SIZE..-1] == ENV_FQ_SUFFIX
      else
        return name[0..(ENV_FQ_PREFIX_SIZE - 1)] == ENV_FQ_PREFIX
      end
    end

    def each_fq_tube(name, &block)
      0.upto(SHARD_COUNT - 1) do |index|
        tube_name = "#{name}_#{index}"
        yield(tube_name)
      end
    end

    def build_hash_from_tubes(tubes)
      hash = Hash(String, AllQ::Tube).new
      tubes.each do |tube|
        hash[tube.name] = tube
      end
      hash
    end

    def tube_name_from_shard_key(name, shard_key : String, tubes)
      if @name_to_index[name]?.nil?
        @name_to_index[name] = 0
      end

      index = Digest::Adler32.checksum(shard_key) % SHARD_COUNT
      "#{name}_#{index}"
    end

    def tube_name(name, index)
      "#{name}_#{index}"
    end

    def check_tube_for_job(raw_name, server_tube_cache)
      tube = server_tube_cache.get_without_create(raw_name)
      if tube
        job = tube.get
      end
      job
    end

    def get(name, server_tube_cache)
      if @name_to_index[name]?.nil?
        @name_to_index[name] = 0
      end

      # Round robin until we find one or we cycle all the way through
      count = 0

      tube_index = @name_to_index[name]
      raw_name = tube_name(name, tube_index)

      job = check_tube_for_job(raw_name, server_tube_cache)
      while job.nil?
        count += 1
        return nil if count == SHARD_COUNT
        tube_index = next_tube_index(name, tube_index)
        raw_name = tube_name(name, tube_index)
        job = check_tube_for_job(raw_name, server_tube_cache)
      end
      @name_to_index[name] = next_tube_index(name, tube_index)
      return job
    end

    def next_tube_index(name, tube_index)
      tube_index += 1
      if tube_index > SHARD_COUNT - 1
        tube_index = 0
      end
      @name_to_index[name] = tube_index
      tube_index
    end

    def clear(name, server_tube_cache)
      each_fq_tube do |raw_name|
        server_tube_cache[raw_name].clear
      end
    end

    def pause(name, paused, server_tube_cache)
      each_fq_tube do |raw_name|
        server_tube_cache[raw_name].pause(paused)
      end
    end
  end
end
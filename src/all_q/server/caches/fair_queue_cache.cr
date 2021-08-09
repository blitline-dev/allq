require "digest"
require "./algorithms/*"

module AllQ
  class FairQueueCache
    SHARD_COUNT        = (ENV["FQ_SHARD_COUNT"]? || 10).to_i
    ENV_FQ_PREFIX      = (ENV["FQ_PREFIX"]? || "fq-")
    ENV_FQ_PREFIX_SIZE = ENV_FQ_PREFIX.size
    ENV_FQ_SUFFIX      = ENV["FQ_SUFFIX"]?
    ENV_FQ_SUFFIX_SIZE = ENV_FQ_SUFFIX.to_s.size

    QUEUE_ALGORITHM_GENERIC                  = 0
    QUEUE_ALGORITHM_TIME_WEIGHTED_FAIR_QUEUE = 1

    def initialize(reserved_cache : ReservedCache)
      @name_to_index = Hash(String, Int32).new
      @reserved_queue = reserved_cache
      if (ENV["TWFQ"]? || "false").to_s.downcase == "true"
        @algorithm = AllQ::FairQueueAlgorithm::TimeWeightedFairQueue.new(SHARD_COUNT)
      else
        @algorithm = AllQ::FairQueueAlgorithm::Generic.new(SHARD_COUNT, @name_to_index, @reserved_queue)
      end
    end

    def set_queuing_algorithm(val : Int32)
      if val == QUEUE_ALGORITHM_GENERIC
        @algorithm = AllQ::FairQueueAlgorithm::Generic.new(SHARD_COUNT, @name_to_index, @reserved_queue)
      elsif val == QUEUE_ALGORITHM_TIME_WEIGHTED_FAIR_QUEUE
        @algorithm = AllQ::FairQueueAlgorithm::TimeWeightedFairQueue.new(SHARD_COUNT)
      end
    end

    def is_fair_queue(name : String)
      if ENV_FQ_SUFFIX
        return false if name.size <= ENV_FQ_SUFFIX_SIZE
        return name[-ENV_FQ_SUFFIX_SIZE..-1] == ENV_FQ_SUFFIX
      else
        return name[0..(ENV_FQ_PREFIX_SIZE - 1)] == ENV_FQ_PREFIX
      end
    end

    def get(name, server_tube_cache)
      @algorithm.get(name, server_tube_cache)
    end

    # def build_hash_from_tubes(tubes)
    #   hash = Hash(String, AllQ::Tube).new
    #   tubes.each do |tube|
    #     hash[tube.name] = tube
    #   end
    #   hash
    # end

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

    def clear(name, server_tube_cache)
      each_fq_tube do |raw_name|
        server_tube_cache[raw_name].clear
      end
    end

    def decorate_job(job, tubes)
      @algorithm.decorate_job(job, tubes)
    end

    def pause(name, paused, server_tube_cache)
      each_fq_tube do |raw_name|
        server_tube_cache[raw_name].pause(paused)
      end
    end

    def each_fq_tube(name, &block)
      0.upto(SHARD_COUNT - 1) do |index|
        tube_name = "#{name}_#{index}"
        yield(tube_name)
      end
    end
  end
end

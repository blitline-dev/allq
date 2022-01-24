require "digest"
require "./algorithms/*"

module AllQ
  class FairQueueCache
    # Proxy for queuing algorithms
    SHARD_COUNT        = (ENV["FQ_SHARD_COUNT"]? || 10).to_i
    ENV_FQ_PREFIX      = (ENV["FQ_PREFIX"]? || "fq-")
    ENV_FQ_PREFIX_SIZE = ENV_FQ_PREFIX.size
    ENV_FQ_SUFFIX      = ENV["FQ_SUFFIX"]?
    ENV_FQ_SUFFIX_SIZE = ENV_FQ_SUFFIX.to_s.size

    QUEUE_ALGORITHM_GENERIC                  = 0
    QUEUE_ALGORITHM_TIME_WEIGHTED_FAIR_QUEUE = 1
    QUEUE_ALGORITHM_TRUE_ROUND_ROBIN         = 2

    def initialize(reserved_cache : ReservedCache)
      @reserved_queue = reserved_cache
      if (ENV["TWFQ"]? || "false").to_s.downcase == "true"
        @algorithm = AllQ::FairQueueAlgorithm::TrueRoundRobin.new(@reserved_queue)
      else
        @algorithm = AllQ::FairQueueAlgorithm::Generic.new(SHARD_COUNT, @reserved_queue)
      end
    end

    # Used for forcing existing FAIR queue algorithm
    # NOTE: This is used primarily for testing, it is NOT intended for production use
    # of changing queuing algorithms dynamically.
    def set_queuing_algorithm(val : Int32)
      if val == QUEUE_ALGORITHM_GENERIC
        @algorithm = AllQ::FairQueueAlgorithm::Generic.new(SHARD_COUNT, @reserved_queue)
      elsif val == QUEUE_ALGORITHM_TRUE_ROUND_ROBIN
        @algorithm = AllQ::FairQueueAlgorithm::TrueRoundRobin.new(@reserved_queue)
      end
    end

    # Determine if queue is fair_queue based on name
    def is_fair_queue(name : String)
      # Handle PREFIX vs SUFFIX
      if ENV_FQ_SUFFIX
        return false if name.size <= ENV_FQ_SUFFIX_SIZE
        return name[-ENV_FQ_SUFFIX_SIZE..-1] == ENV_FQ_SUFFIX
      else
        return name[0..(ENV_FQ_PREFIX_SIZE - 1)] == ENV_FQ_PREFIX
      end
    end

    # Implement Abstract Fair Queue Algorithm contract
    def get(name, server_tube_cache)
      @algorithm.get(name, server_tube_cache)
    end

    def tube_name_from_shard_key(name, shard_key : String, tubes)
      @algorithm.tube_name_from_shard_key(name, shard_key, tubes)
    end

    def clear(name, server_tube_cache)
      @algorithm.pause(name, paused, server_tube_cache)
    end

    def pause(name, paused, server_tube_cache)
      @algorithm.pause(name, paused, server_tube_cache)
    end

    def decorate_job(job, tubes)
      @algorithm.decorate_job(job, tubes)
    end
  end
end

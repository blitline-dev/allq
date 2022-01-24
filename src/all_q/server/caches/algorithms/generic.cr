# Simple sharded fair queue implementation
module AllQ
  class FairQueueAlgorithm
    class Generic < AbstractFairQueueAlgorithm
      @shard_count = 0

      def initialize(shard_count : Int32, reserved_cache : ReservedCache)
        @reserved_cache = reserved_cache
        @name_to_index = Hash(String, Int32).new
        @shard_count = shard_count
        @shard_reservation_limit = Int32.new((ENV["SHARD_RESERVATION_LIMIT"]? || 0).to_i)
      end

      def get(name, server_tube_cache)
        if @name_to_index[name]?.nil?
          @name_to_index[name] = 0
        end

        reservations = @shard_reservation_limit > 0 ? @reserved_cache.reserved_jobs_by_tube : nil
        # Round robin until we find one or we cycle all the way through
        count = 0

        tube_index = @name_to_index[name]
        raw_name = tube_name(name, tube_index)

        job = check_tube_for_job(raw_name, server_tube_cache, reservations)
        while job.nil?
          count += 1
          return nil if count == @shard_count
          tube_index = next_tube_index(name, tube_index)
          raw_name = tube_name(name, tube_index)
          job = check_tube_for_job(raw_name, server_tube_cache, reservations)
        end
        @name_to_index[name] = next_tube_index(name, tube_index)
        return job
      end

      def decorate_job(job, tubes)
        # Do nothing for Generic
      end

      def tube_name(name, index)
        "#{name}_#{index}"
      end

      def pause(name, paused, server_tube_cache)
        each_fq_tube do |raw_name|
          server_tube_cache[raw_name].pause(paused)
        end
      end

      def clear(name, server_tube_cache)
        each_fq_tube do |raw_name|
          server_tube_cache[raw_name].clear
        end
      end

      def tube_name_from_shard_key(name, shard_key : String, tubes)
        if @name_to_index[name]?.nil?
          @name_to_index[name] = 0
        end

        index = Digest::Adler32.checksum(shard_key) % @shard_count
        "#{name}_#{index}"
      end

      private def each_fq_tube(name, &block)
        0.upto(@shard_count - 1) do |index|
          tube_name = "#{name}_#{index}"
          yield(tube_name)
        end
      end

      private def next_tube_index(name, tube_index)
        tube_index += 1
        if tube_index > @shard_count - 1
          tube_index = 0
        end
        @name_to_index[name] = tube_index
        tube_index
      end

      private def check_tube_for_job(raw_name, server_tube_cache, reservations)
        job = nil

        # Check to see if there is a reservation limit
        if reservations && @shard_reservation_limit > 0 && (reservations[raw_name]? || 0) >= @shard_reservation_limit.to_i
          return nil
        end

        tube = server_tube_cache.get_without_create(raw_name)
        if tube
          job = tube.get
        end
        job
      end
    end
  end
end

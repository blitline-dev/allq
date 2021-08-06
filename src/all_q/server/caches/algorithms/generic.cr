# Simple round-robin fair queue implementation
module AllQ
  class FairQueueAlgorithm
    class Generic
      @shard_count = 0
      SHARD_RESERVATION_LIMIT = (ENV["SHARD_RESERVATION_LIMIT"]? || 0).to_i

      property reserved_cache : ReservedCache
      def initialize(shard_count : Int32, name_to_index : Hash(String, Int32), @reserved : ReservedCache)
        @name_to_index = name_to_index
        @shard_count = shard_count
        @reserved_cache = reserved
        @shard_reservation_limit = Int32.new(SHARD_RESERVATION_LIMIT.to_i)
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

      def next_tube_index(name, tube_index)
        tube_index += 1
        if tube_index > @shard_count - 1
          tube_index = 0
        end
        @name_to_index[name] = tube_index
        tube_index
      end

      def check_tube_for_job(raw_name, server_tube_cache, reservations)
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
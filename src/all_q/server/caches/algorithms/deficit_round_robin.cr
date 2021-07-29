# Simple round-robin fair queue implementation
module AllQ
  class FairQueueAlgorithm
    class Generic
      def initialize(name_to_index)
        @name_to_index = name_to_index
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

      def tube_name(name, index)
        "#{name}_#{index}"
      end

      def next_tube_index(name, tube_index)
        tube_index += 1
        if tube_index > SHARD_COUNT - 1
          tube_index = 0
        end
        @name_to_index[name] = tube_index
        tube_index
      end

      def check_tube_for_job(raw_name, server_tube_cache)
        tube = server_tube_cache.get_without_create(raw_name)
        if tube
          job = tube.get
        end
        job
      end

    end
  end
end
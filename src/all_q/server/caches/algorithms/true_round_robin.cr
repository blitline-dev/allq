# True fair queue implementation, as many queues are needed are created
module AllQ
  class FairQueueAlgorithm
    class TrueRoundRobin < AbstractFairQueueAlgorithm
      SHARD_SEPARATOR = (ENV["SHARD_SEPARATOR"]? || ":s:")

      def initialize(reserved_cache : ReservedCache)
        @last_tube = ""
        @queue_name_cache = Array(String).new
        # TODO: We want to add SHARD_RESERVATION_LIMIT for TRR, as such, we would need the reserved count to determine
        # how many jobs are checked out per queue.
        @reserved_cache = reserved_cache
      end

      def get(name, server_tube_cache)
        sync_queue_names(server_tube_cache)

        tube_names = existing_tube_names.select { |tube_name| tube_name.starts_with?("#{name}#{SHARD_SEPARATOR}") }
        tube_names_count = tube_names.size
        raw_name = get_next_tube_name(name, tube_names)

        count = 0
        job = check_tube_for_job(raw_name, server_tube_cache)
        while job.nil?
          count += 1
          return nil if count == tube_names_count
          raw_name = get_next_tube_name(name, tube_names)
          job = check_tube_for_job(raw_name, server_tube_cache)
        end

        job
      end

      def pause(name, paused, server_tube_cache)
        existing_tube_names.each do |raw_name|
          server_tube_cache[raw_name].pause(paused)
        end
      end

      def clear(name, server_tube_cache)
        existing_tube_names.each do |raw_name|
          server_tube_cache[raw_name].clear
        end
      end

      def decorate_job(job, tubes)
        # Do nothing for TrueRoundRobin
      end

      def tube_name_from_shard_key(name, shard_key : String, tubes)
        validation = /^[a-zA-Z0-1][a-zA-Z0-1-_=@\:\$\!\#]*/.match(shard_key)
        if validation
          raise "Invalid shard_key '#{shard_key}', must match REGEX ^[a-zA-Z0-1]+[a-zA-Z0-1-_=@:$!\#]*" unless validation[0].to_s.size == shard_key.size
        else
          raise "Couldn't validate shard_key #{shard_key}, must match REGEX ^[a-zA-Z0-1]+[a-zA-Z0-1-_=@:$!\#]*"
        end
        "#{name}#{SHARD_SEPARATOR}#{shard_key}"
      end

      private def check_tube_for_job(raw_name, server_tube_cache)
        job = nil
        tube = server_tube_cache.get_without_create(raw_name)
        if tube
          job = tube.get
        end
        job
      end

      private def existing_tube_names
        @queue_name_cache
      end

      private def sync_queue_names(server_tube_cache)
        @queue_name_cache = server_tube_cache.tube_names
      end

      private def get_next_tube_name(name, tube_names)
        index = tube_names.index(@last_tube)
        # Cycle back to 0 index
        if index.nil? || (index += 1) == tube_names.size
          index = 0
        end

        @last_tube = tube_names[index]
        @last_tube.to_s
      end
    end
  end
end

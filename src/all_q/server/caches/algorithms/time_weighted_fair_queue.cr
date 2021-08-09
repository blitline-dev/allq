# Time-weighted_fair_queuing_algorithm
# https://en.wikipedia.org/wiki/Fair_queuing#A_byte-weighted_fair_queuing_algorithm
# (revamped for time weighted)
# But with avg job duration as byte weight
# ----------------------------------------------------
# For this approximation we will use the AVG job duration
module AllQ
  class FairQueueAlgorithm
    class TimeWeightedFairQueue
      @shard_count = 0

      def initialize(shard_count)
        @shard_count = shard_count
      end

      def calculate_departure_time_for_unscheduled(tube_name, server_tube_cache)
        # Get average job duration
        avg = GuageStats.get_avg(tube_name).to_i64
        avg = 1 if avg == 0
        # Virtual Departure time in the future = Now + (avg * queue size)
        # Note: This is not exactly correct, it SHOULD be the avg + last job in queue departure time.
        # But we don't have performant access to that info, so we will estimate with this.
        Time.utc.to_unix_f + (server_tube_cache[tube_name].size * avg).to_f
      end

      def get(name, server_tube_cache)
        get_nearest_departure(name, server_tube_cache)
      end

      def get_nearest_departure(name, server_tube_cache)
        job = nil
        # Tubes by departure time
        tubes_by_dt = Hash(String, String).new
        (0...@shard_count).each do |index|
          tn = tube_name(name, index)
          tube = server_tube_cache[tn]
          next_job = tube.peek
          if next_job && next_job.option
            o = next_job.option
            if !o.nil?
              o[0..2] == "dt:"
              tubes_by_dt[tn] = o
            end
          end
        end
        # Find the min Departure Time
        min_tube_name = tubes_by_dt.min_by? { |k, v| v }
        if min_tube_name
          job = server_tube_cache[min_tube_name[0]].get
        end
        job
      end

      def tube_name(name, index)
        "#{name}_#{index}"
      end

      def decorate_job(job, server_tube_cache)
        dt = calculate_departure_time_for_unscheduled(job.tube, server_tube_cache)
        job.option = "dt:#{dt}"
      end
    end
  end
end

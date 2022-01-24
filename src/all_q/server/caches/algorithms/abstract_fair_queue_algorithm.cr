abstract class AbstractFairQueueAlgorithm
  abstract def get(name, server_tube_cache)
  abstract def decorate_job(job, tubes)
  abstract def pause(name, paused, server_tube_cache)
  abstract def clear(name, server_tube_cache)
  abstract def tube_name_from_shard_key(name, shard_key : String, tubes)
end

class FQSpecHelper
  @fair_queue : AllQ::FairQueueCache

  property :stats_handler, :cache_store, :fair_queue

  def initialize
    @cache_store = AllQ::CacheStore.new
    @stats_handler = AllQ::StatsHandler.new(@cache_store)
    @put_handler = AllQ::PutHandler.new(@cache_store)
    @get_handler = AllQ::GetHandler.new(@cache_store)
    @fair_queue = @cache_store.fair_queue
  end

  def send_jobs(count)
    1.upto(count) do |x|
      shard_key = x.to_s
      tube_name = @fair_queue.tube_name_from_shard_key(FQ_TEST_TUBE_NAME, shard_key, @cache_store.tubes.all)
      job = JobSpec.build_job(tube_name, "asdfsd")
      tube = @cache_store.tubes[tube_name]
      tube.put(job)
    end
  end

  def put_single_job(shard_key)
    tube_name = @fair_queue.tube_name_from_shard_key(FQ_TEST_TUBE_NAME, shard_key, @cache_store.tubes.all)
    job = JobSpec.build_job(tube_name, "asdfsd")

    tube = @cache_store.tubes[tube_name]
    tube.put(job)
  end

  def put_using_handler(shard_key)
    json = JobSpec.build_json_params(FQ_TEST_TUBE_NAME, "body part with shard=#{shard_key}", {shard_key: shard_key})
    job_data = @put_handler.process(JSON.parse(json))
    output = JSON.parse(json)
  end

  def get_single_job(delete = false)
    data = JSON.parse({"tube" => FQ_TEST_TUBE_NAME}.to_json)
    job_data_raw = @get_handler.process(data)
    job_data = JSON.parse(job_data_raw.to_json)
    job = job_data["job"]
    if delete
      if job_data
        job_id = job_data["job"].["job_id"]
        @cache_store.reserved.done(job_id)
      end
    end
    job
  end

  def delete(job)
    if job
      job_id = job["job_id"]
      @cache_store.reserved.done(job_id)
    end
  end

  def get_jobs(count)
    1.upto(count) do |x|
      shard_key = x.to_s
      tube_name = @fair_queue.tube_name_from_shard_key(FQ_TEST_TUBE_NAME, shard_key, cache_store.tubes.all)
      tube = @cache_store.tubes[tube_name]

      data = JSON.parse({"tube" => FQ_TEST_TUBE_NAME}.to_json)
      job_data_raw = @get_handler.process(data)
      job_data = JSON.parse(job_data_raw.to_json)
      job_id = job_data["job"].["job_id"]
      @cache_store.reserved.done(job_id)
      # Should be nothing left in the queue
    end
  end

  def stats
    stats = @stats_handler.process(JSON.parse("{}"))
  end
end

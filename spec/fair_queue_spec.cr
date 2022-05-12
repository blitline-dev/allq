require "./spec_helper"
require "./fq_spec_helper"

describe AllQ do
  it "should fair queue as expected" do
    helper = FQSpecHelper.new
    helper.send_jobs(10)
    stats = helper.stats
    # Expect at least 6 shards
    (stats.keys.size > 5).should be_true
    # But no more than 10
    (stats.keys.size < 11).should be_true

    helper.get_jobs(10)
    # Should dequeue all jobs from multiple queues and leave none left

    job = helper.get_single_job
    job.to_json.should eq("{}")
  end

  it "should respect SHARD_RESERVATION_LIMIT" do
    ENV["SHARD_RESERVATION_LIMIT"] = "5"
    helper = FQSpecHelper.new
    1.upto(10) do
      helper.put_single_job("same_shard_key")
    end
    # Make sure there is only 1 shard
    stats = helper.stats
    stats.keys.size.should eq(1)
    # Record only shard (tube_name)
    tube_name = stats.keys[0]

    # Add another shard
    1.upto(10) do
      helper.put_single_job("other_shard_key")
    end

    # Assure both don't end up in same shard
    stats = helper.stats
    (stats.keys.size == 2).should be_true

    1.upto(15) do
      helper.get_single_job
    end

    # Assuming fair queue, the "same_shard_key" shard should only
    # have the MAX of 5 reserved, even though in a fair queue it would
    # have more.
    stats = helper.stats
    stats[tube_name]["reserved"].to_i.should eq(5)
  end
end

it "should respect TrueRoundRobin" do
  helper = FQSpecHelper.new
  helper.fair_queue.set_queuing_algorithm(AllQ::FairQueueCache::QUEUE_ALGORITHM_TRUE_ROUND_ROBIN)
  1.upto(2) do
    helper.put_using_handler("first_shard_key")
  end

  1.upto(1) do
    helper.put_using_handler("second_shard_key")
  end

  1.upto(1) do
    helper.put_using_handler("third_shard_key")
  end

  1.upto(1) do
    helper.put_using_handler("fourth_shard_key")
  end

  stats = helper.stats
  stats.keys.size.should eq(4)
  # Record only shard (tube_name)

  job = helper.get_single_job(true)
  job["tube"].should eq("fq-test:s:first_shard_key")

  job = helper.get_single_job(true)
  job["tube"].should eq("fq-test:s:second_shard_key")

  job = helper.get_single_job(true)
  job["tube"].should eq("fq-test:s:third_shard_key")

  job = helper.get_single_job(true)
  job["tube"].should eq("fq-test:s:fourth_shard_key")

  job = helper.get_single_job(true)
  job["tube"].should eq("fq-test:s:first_shard_key")
end

it "should respect TimeWeightQueue values" do
  # helper = FQSpecHelper.new
  # helper.fair_queue.set_queuing_algorithm(AllQ::FairQueueCache::QUEUE_ALGORITHM_TIME_WEIGHTED_FAIR_QUEUE)
  # 1.upto(1) do
  #   helper.put_using_handler("same_shard_key")
  # end
  # # Make sure there is only 1 shard
  # stats = helper.stats
  # stats.keys.size.should eq(1)
  # # Record only shard (tube_name)
  # tube_name = stats.keys[0]

  # # For long queue time
  # 1.upto(GuageStats::MAX_ARRAY_SIZE) do
  #   GuageStats.push(tube_name, 10)
  # end
  # sleep(6) # This is needed for GuageStats to update internally

  # # Add slow jobs
  # 1.upto(10) do
  #   helper.put_using_handler("same_shard_key")
  # end

  # # Pull out original job
  # helper.get_single_job(true)

  # # -- Start Add fast jobs
  # 1.upto(8) do
  #   helper.put_using_handler("different_key")
  # end

  # 1.upto(8) do
  #   job = helper.get_single_job
  #   job["tube"].should_not eq(tube_name)
  # end
  # # -- End fast jobs

  # # -- Check that slow job is ready to run again
  # sleep(11)
  # job = helper.get_single_job
  # stats = helper.stats
  # job["tube"].should eq(tube_name)

  # # -- Start Add fast jobs again
  # 1.upto(8) do
  #   helper.put_using_handler("different_key")
  # end

  # 1.upto(8) do
  #   job = helper.get_single_job
  #   job["tube"].should_not eq(tube_name)
  # end
  # # -- End fast jobs

  # # -- Finally, finish up slow jobs
  # 1.upto(9) do
  #   job = helper.get_single_job
  #   job["tube"].should eq(tube_name)
  # end
end

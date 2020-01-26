require "./spec_helper"
require "../src/all_q/server/server"

describe AllQ do
  it "should recover on restart as expected" do
    cache_store = AllQ::CacheStore.new
    JobSpec.build_jobs_for_each_state(cache_store)
    tube = cache_store.tubes[TEST_TUBE_NAME]
  end

  it "should throttle as expected" do
    cache_store = AllQ::CacheStore.new
    JobSpec.build_alot_of_jobs(cache_store)
    tube = cache_store.tubes[TEST_TUBE_NAME]
    tube.set_throttle(11)
    time_now = Time.utc
    1.upto(10000) do
      tube.get
    end
    time_newer = Time.utc
    done = 10_000 - tube.size
    done.should eq(11)

    # Remove throttle
    tube.set_throttle(-1)
    1.upto(10_000) do
      tube.get
    end
    done = 10_000 - tube.size
    done.should eq(10_000)
  end

  it "should pause as expected" do
    cache_store = AllQ::CacheStore.new
    JobSpec.build_alot_of_jobs(cache_store)
    tube = cache_store.tubes[TEST_TUBE_NAME]
    tube.pause(true)
    time_now = Time.utc
    1.upto(10000) do
      tube.get
    end
    time_newer = Time.utc
    done = 10_000 - tube.size
    done.should eq(0)

    # Remove pause
    tube.pause(false)
    1.upto(10_000) do
      tube.get
    end
    done = 10_000 - tube.size
    done.should eq(10_000)
  end

  it "should get multiple jobs" do
    cache_store = AllQ::CacheStore.new
    JobSpec.build_alot_of_jobs(cache_store, 100)
    data = {
      tube:   TEST_TUBE_NAME,
      count:  10,
      delete: true,
    }
    jobs_result = AllQ::GetHandler.new(cache_store).process(JSON.parse(data.to_json))
    deser = JSON.parse(jobs_result.to_json)
    if deser["jobs"]
      deser["jobs"].size.should eq(10)
    else
      raise "Must return jobs"
    end
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(90)
  end

  it "should clear a tube" do
    tube = AllQ::Tube.new(TEST_TUBE_NAME)
    job = JobSpec.build_job(TEST_TUBE_NAME, nil)
    job2 = JobSpec.build_job(TEST_TUBE_NAME, nil)
    job3 = JobSpec.build_job(TEST_TUBE_NAME, nil)

    # Load a job into ready, delayed, and reserved
    tube.put(job)
    tube.put(job2, 5, 3600)
    tube.put(job3)
    reseved_job = tube.get

    tube.size.should eq(1)
    tube.delayed_size.should eq(1)

    tube.clear

    tube.size.should eq(0)
    tube.delayed_size.should eq(0)
  end

  it "if serialized clear a tube should remove tube files" do
    if ENV["SERIALIZE"] == "true"
      tube = AllQ::Tube.new(TEST_TUBE_NAME)
      job = JobSpec.build_job(TEST_TUBE_NAME, nil)
      job2 = JobSpec.build_job(TEST_TUBE_NAME, nil)
      job3 = JobSpec.build_job(TEST_TUBE_NAME, nil)

      # Load a job into ready, delayed, and reserved
      tube.put(job)
      tube.put(job2, 5, 3600)
      tube.put(job3)
      reseved_job = tube.get

      tube.size.should eq(1)
      tube.delayed_size.should eq(1)
      files_ready = FileChecker.get_ready(TEST_TUBE_NAME)
      files_ready.size.should eq(1)
      files_delayed = FileChecker.get_delayed(TEST_TUBE_NAME)
      files_delayed.size.should eq(1)
      tube.clear

      tube.size.should eq(0)
      tube.delayed_size.should eq(0)

      files_ready = FileChecker.get_ready(TEST_TUBE_NAME)
      files_ready.size.should eq(0)
      files_delayed = FileChecker.get_delayed(TEST_TUBE_NAME)
      files_delayed.size.should eq(0)
    else
      puts "Skipping test because SERIALIZE is falsey"
    end
  end
end

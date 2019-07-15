require "./spec_helper"
require "../src/all_q/server/server"

describe AllQ do
  # TODO: Write tests

  it "should clear a tube and reserved" do
    cache_store = AllQ::CacheStore.new
    JobSpec.build_jobs_for_each_state(cache_store)
    tube = cache_store.tubes[TEST_TUBE_NAME]

    cache_store.reserved.clear_by_tube(tube.name)

    cache_store.reserved.get_job_ids.size.should eq(0)
  end

  it "if serialized clear a tube a and reserved should remove tube files" do
    if ENV["SERIALIZE"] == "true"
      cache_store = AllQ::CacheStore.new
      JobSpec.build_jobs_for_each_state(cache_store)
      tube = cache_store.tubes[TEST_TUBE_NAME]

      files_delayed = FileChecker.get_reserved
      files_delayed.size.should eq(1)

      cache_store.reserved.clear_by_tube(tube.name)

      files_delayed = FileChecker.get_reserved
      files_delayed.size.should eq(0)
    else
      puts "Skipping test because SERIALIZE is falsey"
    end
  end
end

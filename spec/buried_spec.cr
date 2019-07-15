require "./spec_helper"
require "../src/all_q/server/server"

describe AllQ do
  it "should clear a tube and buried" do
    cache_store = AllQ::CacheStore.new
    JobSpec.build_jobs_for_each_state(cache_store)
    tube = cache_store.tubes[TEST_TUBE_NAME]

    cache_store.buried.clear_by_tube(tube.name)
    cache_store.buried.get_job_ids.size.should eq(0)
  end

  it "if serialized clear a tube a and buried should remove tube files" do
    if ENV["SERIALIZE"] == "true"
      cache_store = AllQ::CacheStore.new
      JobSpec.build_jobs_for_each_state(cache_store)
      tube = cache_store.tubes[TEST_TUBE_NAME]

      files_buried = FileChecker.get_buried
      files_buried.size.should eq(1)

      # Clear stuff
      cache_store.buried.clear_by_tube(tube.name)

      cache_store.buried.get_job_ids.size.should eq(0)

      files_buried = FileChecker.get_buried
      files_buried.size.should eq(0)
    else
      puts "Skipping test because SERIALIZE is falsey"
    end
  end
end

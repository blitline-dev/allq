require "./spec_helper"
require "./fq_spec_helper"

describe AllQ do
  it "should handle guage events" do
    # times in millis
    [1000, 2000, 3000, 4000, 5000, 6000].each do |x|
      GuageStats.push("test_1", x.to_i64)
    end
    GuageStats.instance.run_calc
    output = GuageStats.get_avg("test_1")
    output.should eq(3.5)
  end

  it "guage should allow lots of updates" do
    1.upto(1000).each do |x|
      GuageStats.push("test_1", x.to_i64)
    end
    GuageStats.instance.run_calc
    output = GuageStats.get_avg("test_1")
    output.should eq(0.9505)
  end

  it "guage should handle tps" do
    1.upto(100) do
      GuageStats.push_tps("test_2tps")
    end
    GuageStats.instance.run_calc
    output = GuageStats.get_tps("test_2tps")

    output.should eq(100.0)
    GuageStats.instance.run_calc

    output = GuageStats.get_tps("test_2tps")
    output.should eq(50.0)
  end

  it "integration test with gugage works" do
    helper = FQSpecHelper.new
    1.upto(3) do
      helper.put_using_handler("first_shard_key")
    end
    tube_name = helper.stats.keys[0]
    1.upto(3) do
      job = helper.get_single_job
      sleep(1)
      helper.delete(job)
    end
    GuageStats.instance.run_calc
    output = GuageStats.get_avg(tube_name)
  end
end

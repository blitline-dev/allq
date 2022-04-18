require "./spec_helper"

describe AllQ do
  it "should handle guage events" do
    [1, 2, 3, 4, 5, 6].each do |x|
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
    output.should eq(950.5)
  end

  if "guage should handle tps"
    1.upto(100) do
      GuageStats.push_tps("test_2tps")
    end
    GuageStats.instance.run_calc
    output = GuageStats.get_tps("test_2tps")

    output.should eq(100.0)
    GuageStats.instance.run_calc
    GuageStats.instance.run_calc
    GuageStats.instance.run_calc
    GuageStats.instance.run_calc

    # After 5 samples, this should drop to 20
    # WARNING: There MIGHT be a race condition here
    # since there is a sweeper on GuageStats that might
    # trigger in between running these tests.
    output = GuageStats.get_tps("test_2tps")
    output.should eq(20.0)
  end
end

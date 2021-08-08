require "./spec_helper"

describe AllQ do
  it "should handle guage events" do
    [1, 2, 3, 4, 5, 6].each do |x|
      GuageStats.push("test_1", x.to_i64)
    end
    sleep(2)
    output = GuageStats.get_avg("test_1")
    output.should eq(3)
  end

  it "guage should allow lots of updates" do
    1.upto(1000).each do |x|
      GuageStats.push("test_1", x.to_i64)
    end
    sleep(2)
    output = GuageStats.get_avg("test_1")
    output.should eq(950)
  end
end

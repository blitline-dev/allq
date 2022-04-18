class GuageStats
  AVG_SAMPLE_SIZE = ENV["MAX_ARRAY_SIZE"]? || "100"
  MAX_ARRAY_SIZE = AVG_SAMPLE_SIZE.to_i
  DELAY_BETWEEN_CALC = 5
  TPS_AVG_MAX = 60 / DELAY_BETWEEN_CALC

  property vals = Hash(String, Array(Int64)).new
  property averages = Hash(String, Float64).new  
  property tps_counter =  Hash(String, Int64).new
  property tps_samples =  Hash(String, Array(Int64)).new
  property tps_cache =  Hash(String, Float64).new

  def initialize
    start_sweeper
  end

  def self.push(name : String, val : Int64)
    push_tps(name)
    push_duration(name, val)
  end

  def self.push_tps(name : String)
    count = GuageStats.instance.tps_counter[name]?
    if count.nil?
      GuageStats.instance.tps_counter[name] = 0 
      count = 0
    end
    count += 1
    GuageStats.instance.tps_counter[name] = count.to_i64
  end

  def self.push_duration(name : String, val : Int64)
    result = GuageStats.instance.vals[name]?
    if result.nil?
      GuageStats.instance.vals[name] = Array(Int64).new
      result = GuageStats.instance.vals[name]
    end
    result << val
    if result.size > MAX_ARRAY_SIZE
      result.shift
    end  
  end

  def self.get_avg(name : String) : Float64
    val = GuageStats.instance.averages[name]?
    return Float64.new(0) if val.nil?
    val
  end

  def self.get_tps(name : String) : Float64
    val = GuageStats.instance.tps_cache[name]?
    return Float64.new(0) if val.nil?
    val
  end


  def self.instance
    @@instance ||= new
  end

  def start_sweeper
    spawn do
      loop do
        begin
          run_calc
          sleep(DELAY_BETWEEN_CALC)
        rescue ex
          puts "GuageStats Sweeper Exception..."
          puts ex.inspect_with_backtrace
        end
      end
    end
  end

  def run_calc
    build_tps_samples
    build_averages
  end

  def build_tps_samples
    GuageStats.instance.tps_counter.each do |name, i|
      add_to_tps_samples(name, i)

      # Reset Count, we will capture these at ('DELAY_BETWEEN_CALC') second intervals
      # and reset after 5 seconds.
      GuageStats.instance.tps_counter[name] = 0
    end
  end

  def add_to_tps_samples(name, i)
    avg_array = GuageStats.instance.tps_samples[name]?
    if avg_array.nil?
      GuageStats.instance.tps_samples[name] = Array(Int64).new
      avg_array = GuageStats.instance.tps_samples[name]
    end
    avg_array << i
    avg_array.shift if avg_array.size > TPS_AVG_MAX
    i
  end

  def build_averages
    GuageStats.instance.vals.each do |name, arr|
      if arr.size > 0
        GuageStats.instance.averages[name] = (arr.sum / arr.size).to_f64
      end
    end

    GuageStats.instance.tps_samples.each do |name, arr|
      if arr.size > 0
        GuageStats.instance.tps_cache[name] = (arr.sum / arr.size).to_f64
      end
    end
  end

end

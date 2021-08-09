class GuageStats
  MAX_ARRAY_SIZE = 100

  property vals = Hash(String, Array(Int64)).new
  property averages = Hash(String, Int64).new
  property delay_between_calc = 5

  def initialize
    start_sweeper
    # @vals = Hash(String, Array(Int32)).new
    # @averages = = Hash(String, Array(Int32)).new

    # @vals = Hash(String, Array(Int32)).new
    # @averages = Hash(String, Array(Int32)).new
  end

  def self.push(name : String, val : Int64)
    result = self.instance.vals[name]?
    if result.nil?
      self.instance.vals[name] = Array(Int64).new
      result = self.instance.vals[name]
    end
    result << val
    if result.size > MAX_ARRAY_SIZE
      result.shift
    end
  end

  def self.get_avg(name : String) : Int64
    val = self.instance.averages[name]?
    if val.nil?
      return Int64.new(0)
    end
    return val
  end

  def self.instance
    @@instance ||= new
  end

  def start_sweeper
    spawn do
      loop do
        begin
          build_averages
          sleep(GuageStats.instance.delay_between_calc)
        rescue ex
          puts "GuageStats Sweeper Exception..."
          puts ex.inspect_with_backtrace
        end
      end
    end
  end

  def build_averages
    GuageStats.instance.vals.each do |name, arr|
      if arr.size > 0
        GuageStats.instance.averages[name] = (arr.sum / arr.size).to_i64
      end
    end
  end
end

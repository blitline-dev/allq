require "benchmark"

io = IO::Memory.new

start = Time.utc.to_unix
sleep(2)

Benchmark.ips do |x|
  x.report("from unix") do
    io << Time.utc.to_unix
    io.clear
  end

  x.report("from _s") do
    io <<  Time.utc.to_s("%s").to_i
    io.clear
  end
end


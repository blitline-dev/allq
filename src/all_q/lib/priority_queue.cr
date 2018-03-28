
class PriorityQueue(T)

  def initialize(priority_limit = 10)
    @prioritized_queues = Array(Deque(T)).new
    @min_priority = priority_limit / 2
    1.upto(priority_limit) do
      @prioritized_queues << Deque(T).new
    end
    puts @prioritized_queues.inspect
  end

  def put(item : AllQ::Job, priority : Int32)
    queue = @prioritized_queues[priority]
    if @prioritized_queues.size < priority
      @min_priority = priority if priority < @min_priority
    end
    queue << item
  end

  def get
    item = @prioritized_queues[@min_priority].shift?
    return item if item

    find_next_min
    return @prioritized_queues[@min_priority].shift?
  end

  def size
    size = 0
    @prioritized_queues.each do |i|
      size += i.size
    end
    return size
  end


  def find_next_min
    index = 0
    while(@prioritized_queues[index].size == 0 && index < @prioritized_queues.size - 1)
      index += 1
    end
    if index < @prioritized_queues.size
      @min_priority = index
    else
      @min_priority = @prioritized_queues.size / 2
    end
  end

end


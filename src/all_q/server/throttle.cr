module AllQ
  class Throttle
    property :size

    def initialize(@size : Int32)
      @deque = Deque(Time).new
    end

    def check_and_add?
      t = Time.now
      check(t)
      if @deque.size < @size
        add
        return true
      end
      return false
    end

    def check(time)
      t2 = @deque.shift?
      while (t2 && t2 < time - 1.second)
        t2 = @deque.shift?
      end
      @deque.unshift(t2) if t2
    end

    def add
      @deque << Time.now
    end

    def remove
      @deque.pop
    end
  end
end

class ExpiringCache(T)
  struct CacheItem(X)
    property start, item

    def initialize(@start : Int32, @item : X)
    end
  end

  def initialize(expiration_in_seconds = 3600, @sweep_interval = 5, block : (String -> T)? = nil)
    @cache = Hash(String, CacheItem(T)).new
    @expiration = expiration_in_seconds
    start_sweeper
    @block = block
  end

  def put(name : String, item : T)
    now = Time.now.to_s("%s").to_i
    new_item = CacheItem(T).new(now, item)
    @cache[name] = new_item
  end

  def get(name)
    result = @cache[name]?
    block = @block
    if result.nil? && !block.nil?
      result = block.call(name).as(T)
      put(name, result)
    end
    return result
  end

  def [](key)
    get(key)
  end

  def []=(key : String, value : T)
    put(key, value)
  end

  def size
    @cache.size
  end

  # ------------------------------------
  # --    private
  # ------------------------------------
  def start_sweeper
    spawn do
      loop do
        sweep
        sleep(@sweep_interval)
      end
    end
  end

  def sweep
    puts "Sweeping..."
    now = Time.now.to_s("%s").to_i
    @cache.delete_if do |k, v|
      if v.start < now - @expiration
        puts "deleting #{k}"
      end
      v.start < now - @expiration
    end
  end
end

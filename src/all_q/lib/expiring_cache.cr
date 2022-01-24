class ExpiringCache(T)
  struct CacheItem(X)
    property start, item

    def initialize(@start : Int64, @item : X)
    end
  end

  RENEW = "renew"

  def initialize(expiration_in_seconds = 3600, @sweep_interval = 5, default_value_proc : (String -> T)? = nil, pre_expire_proc : (String -> T)? = nil)
    @cache = Hash(String, CacheItem(T)).new
    @expiration = expiration_in_seconds
    start_sweeper
    @default_value_proc = default_value_proc
    @pre_expire_proc = pre_expire_proc
  end

  def clear
    @cache.clear
  end

  def put(name : String, item : T)
    now = Time.utc.to_unix
    new_item = CacheItem(T).new(now, item)
    @cache[name] = new_item
  end

  def get(name)
    result = @cache[name]?
    default_value_proc = @default_value_proc
    if result.nil? && !default_value_proc.nil?
      result = default_value_proc.call(name).as(T)
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

  def keys
    @cache.keys
  end

  # ------------------------------------
  # --    private
  # ------------------------------------
  def start_sweeper
    spawn do
      loop do
        begin
          sweep
          sleep(@sweep_interval)
        rescue ex
          puts "Expiring Cache Sweeper Exception"
          puts ex.inspect_with_backtrace
        end
      end
    end
  end

  def sweep
    puts "Sweeping Expiring Cache..."
    now = Time.utc.to_unix

    @cache.reject! do |k, v|
      if v.start < now - @expiration
        puts "deleting #{k}"
      end
      should_reject = v.start < now - @expiration
      if should_reject && !@pre_expire_proc.nil?
        output = pre_expire_proc.call(k).as(T)
        if output == RENEW
          should_reject = false
        end
      end
      should_reject
    end
  end
end

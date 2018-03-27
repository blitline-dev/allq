module AllQ
  class CacheStore
    property :tubes, :buried, :reserved
    def initialize
      @tubes = ServerTubeCache.new
      @buried = BuriedCache.new(@tubes)
      @reserved = ReservedCache.new(@tubes, @buried)
    end
  end
end

module AllQ
  class CacheStore
    property :tubes, :buried, :reserved, :parents
    def initialize
      @tubes = ServerTubeCache.new
      @buried = BuriedCache.new(@tubes)
      @parents = ParentCache.new(@tubes, @buried)
      @reserved = ReservedCache.new(@tubes, @buried, @parents)
    end
  end
end

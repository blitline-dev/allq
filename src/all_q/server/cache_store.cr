module AllQ
  class CacheStore
    property :tubes, :buried, :reserved, :parents, :serializer
    BASE_DIR = ENV["SERIALIZER_DIR"]? || "/tmp"

    def initialize
      #      @serializer = Serializer.new(BASE_DIR)
      # unless ENV["PERSIST"]?
      #   puts "Removing persisted data"
      #   @serializer.clear_all
      # end
      @tubes = ServerTubeCache.new
      @buried = BuriedCache.new(@tubes)
      @parents = ParentCache.new(@tubes, @buried)
      @reserved = ReservedCache.new(@tubes, @buried, @parents)
    end

    def run
    end
  end
end

module AllQ
  class CacheStore
    property :tubes, :buried, :reserved, :parents, :fair_queue, :redirect_info
    BASE_DIR = EnvConstants::SERIALIZER_DIR

    def initialize
      @fair_queue = FairQueueCache.new
      @tubes = ServerTubeCache.new
      @buried = BuriedCache.new(@tubes)
      @parents = ParentCache.new(@tubes, @buried)
      @reserved = ReservedCache.new(@tubes, @buried, @parents)
      @redirect_info = nil
    end

    def set_redirect_info(server : String, port : String)
      @redirect_info = RedirectInfo.new(server, port)
    end

    def redirect?
      return !@redirect_info.nil?
    end

    def clear_all
      @tubes.clear_all
      @buried.clear_all
      @tubes.clear_all
      @reserved.clear_all
      @parents.clear_all
    end

    struct RedirectInfo
      property server, port

      def initialize(@server : String, @port : String)
      end
    end
  end
end

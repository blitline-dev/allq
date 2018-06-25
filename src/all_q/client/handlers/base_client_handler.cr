module AllQ
  class BaseClientHandler
    def initialize(@server_connections : Hash(String, ServerConnection))
    end
  end
end

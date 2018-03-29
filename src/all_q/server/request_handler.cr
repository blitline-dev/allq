require "json"

module AllQ
  class RequestHandler
    def initialize(@cacheStore : AllQ::CacheStore)
    end

    def process(body)
      begin
        body_hash = JSON.parse(body).as_h
        result = Hash(String, Hash(String, String)).new
        result = action(body_hash["action"], body_hash["params"].as(Hash(String, JSON::Type)))
        puts result.to_json
        return result.to_json
      rescue ex
        puts ex.inspect_with_backtrace
        return "error: #{ex.message}" 
      end
    end

    def action(name, params)
      result = Hash(String, Hash(String, String)).new
      case name
        when "put"
          result = PutHandler.new(@cacheStore).process(params)
        when "get"
          result = GetHandler.new(@cacheStore).process(params)
        when "stats"
          result = StatsHandler.new(@cacheStore).process(params)
        when "delete"
          result = DeleteHandler.new(@cacheStore).process(params)

        else
          puts "illegal action"
      end
      return result
    end

  end
end
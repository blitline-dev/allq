require "json"

module AllQ
  class RequestHandler
    PING = "ping"
    PONG = "pong"

    def initialize(@cacheStore : AllQ::CacheStore)
      @action_count = 0
      @debug = false
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
    end

    def process(body)
      begin
        return PONG if body == PING
        body_hash = JSON.parse(body).as_h
        result = Hash(String, Hash(String, String)).new
        result = action(body_hash["action"], body_hash["params"].as(Hash(String, JSON::Type)))
        puts "results from #{body_hash["action"]?.to_s} #{result.to_json}" if @debug
        return result.to_json
      rescue ex
        puts ex.inspect_with_backtrace
        return "error: #{ex.message}"
      end
    end

    def action(name, params)
      result = Hash(String, Hash(String, String)).new
      @action_count += 1
      @action_count = 0 if @action_count == Int32::MAX - 1
      case name
      when "put"
        result = PutHandler.new(@cacheStore).process(params)
      when "get"
        result = GetHandler.new(@cacheStore).process(params)
      when "stats"
        result = StatsHandler.new(@cacheStore).process(params)
        result["global"] = Hash(String, String).new
        result["global"]["action_count"] = @action_count.to_s
        puts result.inspect if @debug
      when "delete"
        result = DeleteHandler.new(@cacheStore).process(params)
      when "done"
        result = DoneHandler.new(@cacheStore).process(params)
      when "set_parent_job"
        result = SetParentJobHandler.new(@cacheStore).process(params)
      when "set_children_started"
        result = SetChildrenStartedHandler.new(@cacheStore).process(params)
      when "touch"
        result = TouchHandler.new(@cacheStore).process(params)
      when "admin"
        result = AdminHandler.new(@cacheStore).process(params)
      when "clear"
        result = ClearHandler.new(@cacheStore).process(params)
      when "peek"
        result = PeekHandler.new(@cacheStore).process(params)
      when "bury"
        result = BuryHandler.new(@cacheStore).process(params)
      when "kick"
        result = KickHandler.new(@cacheStore).process(params)
      when "release"
        result = ReleaseHandler.new(@cacheStore).process(params)
      else
        puts "illegal action"
      end
      return result
    end
  end
end

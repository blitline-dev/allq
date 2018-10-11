require "json"

module AllQ
  class RequestHandler
    PING      = "ping"
    PONG      = "pong"
    VERSION   = "version"
    LOCAL_MAX = Int32::MAX - 10

    def initialize(@cacheStore : AllQ::CacheStore)
      @action_count = 0
      @debug = false # INFER TYPE
      @debug = (ENV["ALLQ_DEBUG"]?.to_s == "true")
    end

    def process(body : String)
      begin
        return PONG if body == PING
        return ENV["VERSION"]?.to_s if body == VERSION

        body_hash = JSON.parse(body)
        result = action(body_hash["action"], body_hash["params"])
        puts "results from #{body_hash["action"]?.to_s} #{result}" if @debug
        return result
      rescue ex
        puts ex.inspect_with_backtrace
        return "error: #{ex.message}"
      end
    end

    def action(name, params : JSON::Any) : String
      result : HandlerResponse | Nil
      @action_count += 1
      @action_count = 0 if @action_count > LOCAL_MAX
      case name
      when "put"
        result = PutHandler.new(@cacheStore).process(params)
        # Currently the gem looks for "job" node, but in the future it will
        # look for response.job_id. For right now, we need to hack a response
        # that won't break existing functionality
        job_id = result.job_id
        hack_output = "{\"response\": {\"action\": \"put\",\"job_id\": \"#{job_id}\"},\"job\": {\"job_id\": \"#{job_id}\"}}"
        return hack_output
      when "get"
        result = GetHandler.new(@cacheStore).process(params)
      when "stats"
        hash_output = StatsHandler.new(@cacheStore).process(params)
        hash_output["global"] = Hash(String, String).new
        hash_output["global"]["action_count"] = @action_count.to_s
        puts hash_output.inspect if @debug && hash_output.to_s.size > 0
        return hash_output.to_json
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
      when "clear"
        result = ClearHandler.new(@cacheStore).process(params)
      when "peek"
        result = PeekHandler.new(@cacheStore).process(params)
      when "pause"
        result = PauseHandler.new(@cacheStore).process(params)
      when "unpause"
        result = UnpauseHandler.new(@cacheStore).process(params)
      when "bury"
        result = BuryHandler.new(@cacheStore).process(params)
      when "kick"
        result = KickHandler.new(@cacheStore).process(params)
      when "release"
        result = ReleaseHandler.new(@cacheStore).process(params)
      when "throttle"
        result = ThrottleHandler.new(@cacheStore).process(params)
      when "admin"
        hash_output = AdminHandler.new(@cacheStore).process(params)
        puts hash_output.inspect if @debug && hash_output.to_s.size > 0
        return hash_output.to_json
      else
        puts "illegal action"
      end

      if result
        response = JSONResponse.new(result)      
        return response.to_json
      else
        return "{}"
      end
    end
  end
end

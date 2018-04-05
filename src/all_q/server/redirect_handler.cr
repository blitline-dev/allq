module AllQ
  class RedirectHandler
    def initialize(@cache_store : AllQ::CacheStore, @request_handler : AllQ::RequestHandler)
    end

    def process(body)
      begin
        body_hash = JSON.parse(body).as_h
        result = Hash(String, Hash(String, String)).new
        result = action(body_hash["action"], body_hash["params"].as(Hash(String, JSON::Type)))
        return result.to_json
      rescue ex
        puts ex.inspect_with_backtrace
        return "error: #{ex.message}"
      end
    end

    def action(name, params)
      result = Hash(String, Hash(String, String)).new
      case name
      when "get"
        # -- Don't allow new 'gets' during redirect phase, this
        # -- is effectively the 'drain' process, we will wait
        # -- for queues to be empty before
        # -- actually sending redirect
        result = Hash(String, Hash(String, String)).new
        if ok_to_redirect?
          server_hash = Hash(String, String).new
          server_hash["name"] = "redirect"
          redirect_info = @cache_store.redirect_info
          if redirect_info
            server_hash["server"] = redirect_info.server
            server_hash["port"] = redirect_info.port
          end
          result["admin"] = server_hash
        end
      else
        result = @request_handler.action(name, params)
      end
      return result
    end

    def ok_to_redirect?
      return false if @cache_store.redirect_info.nil?
      is_ok = true
      stats_handler = StatsHandler.new(@cache_store)
      results = stats_handler.process(Hash(String, JSON::Type).new)
      results.each do |tube_name, stats|
        stats.each do |k, v|
          is_ok = false if v.to_i > 0
        end
      end
      return is_ok
    end
  end
end

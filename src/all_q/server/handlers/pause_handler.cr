require "./base_handler"

# ---------------------------------
# Action: pause
# Params:
#     tube : <tube name> (pause tube, get returns nil, put ok)
# ---------------------------------

module AllQ
  class PauseHandler < BaseHandler
    def status
      return true
    end

    def process(json : JSON::Any)
      handler_response = HandlerResponse.new("pause")

      data = normalize_json_hash(json)
      name = ""
      if data["tube"]?
        name = data["tube"]
      end
      @cache_store.tubes.all.each do |tube|
        if tube.name == name
          tube.pause(status)
        end
      end
      return handler_response
    end
  end

  class UnpauseHandler < PauseHandler
    def status
      return false
    end
  end
end

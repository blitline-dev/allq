require "json"

module AllQ
  class Parser
    def self.parse(input : String) : JSON::Any
      # json_data = JSON.parse(input)
      # ret_val = json_data
      return JSON.parse(input)
    end
  end
end

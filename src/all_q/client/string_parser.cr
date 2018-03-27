require "json"

module AllQ
  class Parser

    def self.parse(input : String)
      json_data = JSON.parse(input)
      ret_val = json_data.as_h
      return ret_val
    end

  end
end
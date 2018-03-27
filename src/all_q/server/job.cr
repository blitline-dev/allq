require "json"

module AllQ
  class Job

    property id : String
    property parent_id : String | Nil
    property body : String
    property tube : String
    property reserved : Bool
    property ttl : Int32
    property expired_count : Int32
    property expired_limit : Int32

    def initialize(data : Hash(String, String), @tube : String)
      @ttl = data["ttl"]? ? data["ttl"].to_i : 3600
      @id = data["id"]? || Random::Secure.urlsafe_base64
      @parent_id = data["parent_id"]?
      @body = data["body"]? || ""
      @expired_count = 0
      @expired_limit = 3
      @reserved = false
    end

    def to_hash
      data = Hash(String, String).new
      data["id"] = @id
      data["body"] = @body
      data["tube"] = @tube
      data["expired_count"] = @expired_count.to_s
      return data
    end




  end
end
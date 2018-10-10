require "json"

struct HandlerResponse
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  property action : String | Nil= nil
  property job_id : String | Nil = nil
  property error : String | Nil = nil
  property value : String | Nil = nil  
  property job : Hash(String, String) | Nil = nil

  def initialize(@action : String)
  end

  def job=(job)
    @job = job
  end

end

struct JSONResponse
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  @response : HandlerResponse
  @job : Hash(String, String) | Nil = nil

  def initialize(@response : HandlerResponse)
    if @response.job
      @job = @response.job
    end
  end

end
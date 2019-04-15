require "json"

struct HandlerResponse
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  property action : String | Nil = nil
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

struct HandlerResponseMultiple
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  property action : String | Nil = nil
  property error : String | Nil = nil
  property value : String | Nil = nil
  property jobs : Array(Hash(String, String))

  def initialize(@action : String)
    @jobs = Array(Hash(String, String)).new
  end

  def add_job(job)
    @jobs << job
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

struct JSONResponseMultiple
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  @response : HandlerResponseMultiple
  @jobs : Array(Hash(String, String)) | Nil = nil

  def initialize(@response : HandlerResponseMultiple)
    if @response.jobs
      @jobs = @response.jobs
    end
  end
end

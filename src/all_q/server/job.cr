require "json"
require "cannon"
require "random"

class JobFactory
  property id : String
  property parent_id : String
  property body : String
  property tube : String
  property reserved : Bool
  property noop : Bool
  property ttl : Int32
  property expireds : Int32
  property expired_limit : Int32
  property priority : Int32
  property releases : Int32

  def initialize(data : Hash(String, String), @tube : String, priority : Int32)
    @ttl = data["ttl"]? ? data["ttl"].to_i : 3600
    @id = data["id"]? || Random::Secure.urlsafe_base64
    @parent_id = data["parent_id"]?.to_s
    @body = data["body"]? || ""
    @expireds = 0
    @releases = 0
    @priority = priority
    @priority = 1 if @priority == 0
    @expired_limit = data["expired_limit"]? ? data["expired_limit"].to_i : 3
    @reserved = false
    @noop = data["noop"]? ? data["noop"].to_s == "true" : false
    if @noop
      raise "Noop jobs MUST have a parent ID" unless @parent_id
    end
  end

  def get_job
    job = Job.new(@id, @parent_id, @body, @tube, @reserved, @noop, @ttl, @expireds, @expired_limit, @priority, @releases)
    return job
  end

  def self.to_hash(job)
    data = Hash(String, String).new
    data["job_id"] = job.id
    data["body"] = job.body
    data["tube"] = job.tube
    data["expireds"] = job.expireds.to_s
    data["releases"] = job.releases.to_s
    return data
  end
end

struct Job
  include Cannon::Auto

  property id : String
  property parent_id : String | Nil
  property body : String
  property tube : String
  property reserved : Bool
  property noop : Bool
  property ttl : Int32
  property expireds : Int32
  property expired_limit : Int32
  property priority : Int32
  property releases : Int32

  def initialize(@id, @parent_id, @body, @tube, @reserved, @noop, @ttl, @expireds, @expired_limit, @priority, @releases)
  end
end

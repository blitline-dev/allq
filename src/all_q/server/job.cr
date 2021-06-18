require "json"
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
  property created_time : Int64

  TTL = ENV["DEFAULT_TTL"]? || 3600

  def self.build_job_factory_from_hash(data : JSON::Any)
    priority = data["priority"]? ? data["priority"] : 5

    JobFactory.new(normalize_json_hash(data), data["tube"].to_s, priority.to_s.to_i)
  end

  def self.normalize_json_hash(json_hash : JSON::Any)
    h = Hash(String, String).new
    json_hash.as_h.each do |k, v|
      h[k.to_s] = v.to_s
    end
    return h
  end

  def initialize(data : Hash(String, String), @tube : String, priority : Int32)
    @ttl = data["ttl"]? ? data["ttl"].to_i : TTL.to_i
    @id = data["id"]? || Random::Secure.urlsafe_base64
    @parent_id = data["parent_id"]?.to_s
    @body = data["body"]? || ""
    @expireds = 0
    @releases = 0
    @created_time = Time.utc.to_unix_ms
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
    job = Job.new(@id, @parent_id, @body, @tube, @reserved, @noop, @ttl, @expireds, @expired_limit, @priority, @releases, @created_time)
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
  include JSON::Serializable
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
  property created_time : Int64

  def initialize(@id, @parent_id, @body, @tube, @reserved, @noop, @ttl, @expireds, @expired_limit, @priority, @releases, @created_time)
  end
end

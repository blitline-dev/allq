require "http/server"
require "json"

struct AllQJob
  include JSON::Serializable
  property id : String = ""
  property body : String = ""
  property tube : String = ""
  property expireds : Int32 = 0
  property releases : Int32 = 0

  def initialize(@id)
  end
end

struct AllQStats
  include JSON::Serializable

  property tube : String = ""
  property ready : Int32 = 0
  property reserved : Int32 = 0
  property delayed : Int32 = 0
  property buried : Int32 = 0
  property parents : Int32 = 0
  property throttle_size : Int32 | Nil = nil
  property avg : Float64 = 0
  property tps : Float64 = 0

  def initialize(@tube)
  end
end

struct AllQStatsServer
  include JSON::Serializable
  property server_name : String = ""
  property action_count : Int32 = 0
  property job_put : Int32 = 0
  property job_get : Int32 = 0
  property stats : Array(AllQStats) = Array(AllQStats).new

  def initialize(@server_name)
  end
end

struct AllQHttpClientActionParams
  property action, params

  def initialize(@action : String, @params : String)
  end
end

class AllQHttpClient
  HTTP_SERVER_PORT = (ENV["HTTP_SERVER_PORT"]? || "8090").to_i
  SUPPORTED_GET    = ["stats"]

  def initialize(@debug : Bool, @sender : AllQ::Client)
    @connections = 0
    @version = ENV["CL_VERSION"]? || "0.0.0.0"

    server = HTTP::Server.new do |context|
      begin
        context.response.content_type = "application/json"
        ap = handle_context(context)
        process(ap, context)
      rescue ex
        puts ex.inspect_with_backtrace
        puts "OK...Continuing"
      end
    end

    server.bind_tcp "0.0.0.0", HTTP_SERVER_PORT
    puts "Listening on http://0.0.0.0:#{HTTP_SERVER_PORT}"
    server.listen
  end

  def handle_post(url_base, body, context) : AllQHttpClientActionParams
    ap = AllQHttpClientActionParams.new("noop", "")

    case url_base
    when "job"
      ap = AllQHttpClientActionParams.new("put", body)
    when "throttle"
      ap = AllQHttpClientActionParams.new("throttle", body)
    when "parent_job"
      ap = AllQHttpClientActionParams.new("set_parent_job", body)
    else
      raise "Unhandled http url_base = #{url_base}"
    end
    return ap
  end

  def handle_get(url_base, body, context) : AllQHttpClientActionParams
    query_params = context.request.query_params
    ap = AllQHttpClientActionParams.new("noop", "")
    case url_base
    when "multiple_job"
      tube = query_params["tube"]? || query_params["tube_name"]?
      count = query_params["count"].to_i
      delete = query_params["delete"]?

      count = 1 if count < 1
      if tube
        if delete
          body = %({ "tube" : "#{tube}", "count" : "#{count}", "delete" : #{delete} })
        else
          body = %({ "tube" : "#{tube}", "count" : "#{count}" })
        end
        ap = AllQHttpClientActionParams.new("get_multiple_jobs", body)
      else
        raise "Tube name required for get"
      end
    when "job"
      tube = query_params["tube"]? || query_params["tube_name"]?
      delete = query_params["delete"]?

      if tube
        if delete
          body = %({ "tube" : "#{tube}",  "delete" : #{delete} })
        else
          body = %({ "tube" : "#{tube}" })
        end
        ap = AllQHttpClientActionParams.new("get", body)
      else
        raise "Tube name required for get"
      end
    when "stats"
      ap = AllQHttpClientActionParams.new("stats", "{}")
    when "peek"
      tube = query_params["tube"]? || query_params["tube_name"]?
      if tube
        buried = query_params["buried"]? || "false"
        body = %({ "tube" : "#{tube}", "buried" : "#{buried}" })
        ap = AllQHttpClientActionParams.new("peek", body)
      else
        raise "Tube name required for peek"
      end
    else
      raise "Unhandled http url_base = #{url_base}"
    end
    return ap
  end

  def handle_put(url_base, body, context) : AllQHttpClientActionParams
    query_params = context.request.query_params
    ap = AllQHttpClientActionParams.new("noop", "")
    job_id = query_params["job_id"]? || "unknown"
    body = %({ "job_id" : "#{job_id}" })

    case url_base
    when "touch"
      ap = AllQHttpClientActionParams.new("touch", body)
    when "kick"
      ap = AllQHttpClientActionParams.new("kick", body)
    when "bury"
      ap = AllQHttpClientActionParams.new("bury", body)
    when "release"
      ap = AllQHttpClientActionParams.new("release", body)
    when "set_children_started"
      ap = AllQHttpClientActionParams.new("set_children_started", body)
    else
      raise "Unhandled http url_base = #{url_base}"
    end
    return ap
  end

  def handle_delete(url_base, body, context) : AllQHttpClientActionParams
    query_params = context.request.query_params
    ap = AllQHttpClientActionParams.new("noop", "")
    job_id = query_params["job_id"]? || "unknown"
    body = %({ "job_id" : "#{job_id}" })

    case url_base
    when "job"
      if query_params["tube"]?
        tube = query_params["tube"]? || ""
        body = %({ "job_id" : "#{job_id}", "tube" : "#{tube}" }) unless tube.empty?
      end
      ap = AllQHttpClientActionParams.new("delete", body)
    when "tube"
      tube = query_params["tube"]? || "unknown"
      cache_type = query_params["cache_type"]? || "all"
      body = %({ "tube" : "#{tube}", "cache_type" : "#{cache_type}" })
      ap = AllQHttpClientActionParams.new("clear", body)
    else
      raise "Unhandled http url_base = #{url_base}"
    end
    return ap
  end

  def handle_context(context)
    resource = context.request.path.downcase.delete('/')
    method = context.request.method.upcase
    body_io = context.request.body
    body = ""

    if body_io
      body = body_io.gets_to_end
    end

    case (method)
    when "POST"
      ap = handle_post(resource, body, context)
    when "PUT"
      ap = handle_put(resource, body, context)
    when "GET"
      ap = handle_get(resource, body, context)
    when "DELETE"
      ap = handle_delete(resource, body, context)
    else
      raise "Unhandled http method = #{method}"
    end

    return ap
  end

  def process(action_params : AllQHttpClientActionParams, context)
    return if action_params.action.empty?
    data = "{\"action\" : \"#{action_params.action}\", \"params\" : #{action_params.params}}"
    do_stuff(data, context, action_params)
  end

  def remap_stats(result, context)
    server_stats = Array(AllQStats).new
    servers = Array(AllQStatsServer).new

    json_results = JSON.parse(result)
    json_results_as_hash = json_results.as_h
    json_results_as_hash.each do |server_hash, tube_hash|
      tube_hash_as_hash = tube_hash.as_h
      global = tube_hash_as_hash.delete("global")
      allq_stats_server = AllQStatsServer.new(server_hash)
      tube_hash_as_hash.each do |tube_name, metrics|
        allq_stats_server.stats << build_server_stats(tube_name, metrics)
        if global
          allq_stats_server.action_count = global["action_count"]? ? global["action_count"].to_s.to_i : 0
          allq_stats_server.job_put = global["job_put"]? ? global["job_put"].to_s.to_i : 0
          allq_stats_server.job_get = global["job_get"]? ? global["job_get"].to_s.to_i : 0
        end
      end
      servers << allq_stats_server
    end
    context.response.print(servers.to_json)
  end

  def remap_throttle(result, context)
    throttle = Hash(String, String).new
    throttle["action"] = "throttle"
    throttle["value"] = "true"
    context.response.print(throttle.to_json)
  end

  def return_job_id(result, context)
    return_hash = Hash(String, String).new
    vals = JSON.parse(result)
    vals = vals["response"]?

    if vals && vals["job_id"]?
      return_hash["id"] = vals["job_id"].to_s
      context.response.print(vals.to_json)
    else
      raise "Failed to find job_id is results"
    end
  end

  def remap_multiple_jobs(result, context)
    multiple_jobs_response = JSON.parse(result)
    jobs = multiple_jobs_response["jobs"].as_a
    job_object_array = Array(AllQJob).new
    jobs.each do |output|
      job = AllQJob.new(output["job_id"].to_s)
      job.body = output["body"].to_s
      job.tube = output["tube"].to_s
      job.expireds = output["expireds"].to_s.to_i
      job.releases = output["releases"].to_s.to_i
      job_object_array << job
    end
    response_object = Hash(String, Array(AllQJob)).new
    response_object["jobs"] = job_object_array
    context.response.print(response_object.to_json)
  end

  def remap_job(result, context)
    results_job_data = JSON.parse(result)

    if results_job_data["job"]?
      output = results_job_data["job"]
      if output["job_id"]?
        job = AllQJob.new(output["job_id"].to_s)
        job.body = output["body"].to_s
        job.tube = output["tube"].to_s
        job.expireds = output["expireds"].to_s.to_i
        job.releases = output["releases"].to_s.to_i
        context.response.print(job.to_json)
      else
        context.response.print("{}")
      end
    else
      raise "Failed to build job in client"
    end
  end

  def do_stuff(data, context, action_params)
    result = @sender.send(data)
    begin
      case (action_params.action)
      when "stats"
        remap_stats(result, context)
        return
      when "throttle"
        remap_throttle(result, context)
        return
      when "get", "peek"
        remap_job(result, context)
        return
      when "get_multiple_jobs"
        remap_multiple_jobs(result, context)
        return
      when "clear"
        context.response.print("{}")
        return
      when "set_parent_job", "put"
        return_job_id(result, context)
        return
      end
    rescue exception
      puts "Failed to parse results from server: #{exception.inspect_with_backtrace} #{action_params.action}"
    end
    begin
      json_results = JSON.parse(result)
    rescue ex
      puts "Failed to pase JSON '#{result}'"
      json_results = JSON.parse("{\"error\": \"Failed to parse #{result}\"}")
    end
    context.response.print(json_results["response"].to_json)
  end

  def build_server_stats(tube_name, metrics) : AllQStats
    s = AllQStats.new(tube_name)
    begin
      s.tube = tube_name
      s.ready = metrics["ready"].to_s.to_i
      s.reserved = metrics["reserved"].to_s.to_i
      s.delayed = metrics["delayed"].to_s.to_i
      s.buried = metrics["buried"].to_s.to_i
      s.parents = metrics["parents"].to_s.to_i
      s.throttle_size = metrics["throttle_size"].to_s.to_i if metrics["throttle_size"]?
      s.avg = metrics["avg"].to_s.to_f64.round(2) if metrics["avg"]?
      s.tps = metrics["tps"].to_s.to_f64.round(2) if metrics["tps"]?
    rescue ex
      puts ex.inspect_with_backtrace
    end
    return s
  end
end

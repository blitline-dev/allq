require "http/server"
require "json"

struct AllQHttpClientActionParams
  property action, params

  def initialize(@action : String, @params : String)
  end
end

class AllQHttpClient
  HTTP_SERVER_PORT = 8090
  SUPPORTED_GET = ["stats", "get"]


  def initialize(@debug : Bool, @sender : AllQ::Client)
    @connections = 0
    @version = ENV["CL_VERSION"]? || "0.0.0.0"

    server = HTTP::Server.new do |context|
      context.response.content_type = "applcation/json"
      ap = handle_context(context)
      process(ap, context)
    end

    server.bind_tcp "127.0.0.1", HTTP_SERVER_PORT
    puts "Listening on http://127.0.0.1:#{HTTP_SERVER_PORT}"
    server.listen

  end

  def handle_context(context)
    resource = context.request.resource.downcase.delete('/')
    method = context.request.method.upcase
    action = ""
    puts "ehre" + resource.to_s
    if "POST" == method
      action = resource
      body_io = context.request.body
      if body_io
        body_data = body_io.gets_to_end
        parse_data = JSON.parse(body_data)
        params = parse_data["data"].to_json
      else
        params = "{}"
      end
    elsif "GET" == method
      if SUPPORTED_GET.includes?(resource)
        action = resource
        params = "{}"
      end
    end
    puts [action.to_s, params.to_s].inspect
    ap = AllQHttpClientActionParams.new(action.to_s, params.to_s)
    return ap
  end

  def process(action_params : AllQHttpClientActionParams, context)
    return if action_params.action.empty?
    data = "{\"action\" : \"#{action_params.action}\", \"params\" : #{action_params.params}}"
    do_stuff(data, context)
  end

  def do_stuff(data, context)
    puts "Sending ->" + data
    result = @sender.send(data)
    context.response.print(result)
  end

end
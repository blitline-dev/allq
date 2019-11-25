require 'json'
require 'socket'

@socket_location = ENV.fetch('SOCKET_LOCATION')
@action_name = ENV.fetch('ACTION_NAME')
@path = ENV.fetch('WATCH_PATH')
@param_name = ENV.fetch('PARAM_NAME')

@cached_value = nil

def build_json(value)
  v = {
      action: @action_name,
      params: {
      }
  }
  v[:params][@param_name] = value
  return v.to_json
end

def get_value
  action = `curl -s https://wfw9bp6mw6.execute-api.us-east-1.amazonaws.com/Production/nodes?key=#{@path}`
  response = JSON.parse(action)
  value = response['value']
  raise "#{response}, missing value of #{@path}" if value.nil? || value.empty?

  value
end

def send_to_socket(socket_location, data)
  socket = UNIXSocket.new(socket_location)
  socket.write("#{data}\n")
  socket.close
end

def check_value
  location = get_value
  if @cached_value
    if location != @cached_value
      json = build_json(location)
      puts json
      STDOUT.flush
      send_to_socket(@socket_location, json)
    end
  end
  @cached_value = location
end

@cached_value = get_value
puts "Loaded #{@cached_value}"

loop do
  begin
    sleep(15)
    check_value
    sleep(15)
  rescue => ex
    puts ex.message
    puts ex.backtrace
  end
end


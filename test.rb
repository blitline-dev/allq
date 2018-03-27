require 'json'

def put(val = nil)
	p = {
  	action: "put",
  	params: {
    	tube: "tube-1",
    	body: val || (0...8).map { (65 + rand(26)).chr }.join,
      ttl: "20",
		  delay: "10"
  	}
	}
	
	puts `echo '#{p.to_json}' | socat - tcp4-connect:127.0.0.1:7766`
end

def get
  p = {
    action: "get",
    params: {
      tube: "tube-1"
    }
  }

  puts `echo '#{p.to_json}' | socat - tcp4-connect:127.0.0.1:7766`
end

def stats
 p = {
   action: "stats",
   params: {
     tube: "tube-1"
   }
 }
  puts `echo '#{p.to_json}' | socat - tcp4-connect:127.0.0.1:7766`
end


1.upto(1) do
  put
end

get

loop do
  stats
  sleep(1)
end

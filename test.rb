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
	
#	puts `echo '#{p.to_json}' | socat - tcp4-connect:127.0.0.1:7766`
end

def get
  p = {
    action: "get",
    params: {
      tube: "tube-1"
    }
  }

  output = `echo '#{p.to_json}' | socat - tcp4-connect:127.0.0.1:7766`
	return if output.empty?
  puts output
  o = JSON.parse(output)
  puts o.inspect
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

stats
exit 0;

def random_stuff
	v = rand(10)
  if v < 3
		job = get
  elsif v < 8
    put
  else
    stats
  end
end

i = 0
loop do
  i += 1
  random_stuff
  puts i.to_s
#  sleep(1)
end

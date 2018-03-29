require 'json'

DEBUG = true

class Test
  def send_to_server(hash)
    output_string = "echo '#{hash.to_json}' | socat - tcp4-connect:127.0.0.1:7766"
    puts output_string if DEBUG
    output = `#{output_string}`
    puts 'RETURNED -------->' + output if DEBUG
    return {} if output.empty?
    JSON.parse(output)
  end

  def put(val = nil, merge_data= {})
  	p = {
    	action: "put",
    	params: {
      	tube: "tube-1",
      	body: val || (0...8).map { (65 + rand(26)).chr }.join
    	}
  	}
    p[:params].merge!(merge_data)
    send_to_server(p)
  end

  def delete(job_id)
    p = {
      action: "delete",
      params: {
        job_id: job_id
      }
    }
    send_to_server(p)
  end

  def get
    p = {
      action: "get",
      params: {
        tube: "tube-1"
      }
    }
    output = send_to_server(p)
    return output
  end

  def stats
   p = {
     action: "stats",
     params: {
       tube: "tube-1"
     }
   }
   output = send_to_server(p)
   puts output.inspect
  end

  def send_random
    loop do
      i += 1
      random_stuff
      puts i.to_s
   #  sleep(0.1)
    end
  end

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

  def put_get_delete
    put
    out = get
    job_id = out["job"]["id"]
    delete(job_id)
  end

  def get_delete
    out = get
    job_id = out["job"]["id"]
    delete(job_id)
  end


end


  t = Test.new
  t.put(nil, { ttl: 20})

  t = Test.new
  t.put(nil, { ttl: 20})

  t = Test.new
  t.put(nil, { ttl: 20})

  t = Test.new
  t.put(nil, { ttl: 20})

  t = Test.new
  t.put(nil, { ttl: 20})
1.upto(200) do
	t = Test.new
#  t.put(nil, { ttl: 20})
	t.get
	t.stats
  sleep(3)
end


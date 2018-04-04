require 'json'

DEBUG = true

class Functions
  def send_to_server(hash)
    output_string = "echo '#{hash.to_json}' | socat - tcp4-connect:127.0.0.1:7766"
    puts output_string if DEBUG
    output = `#{output_string}`
    puts 'RETURNED -------->' + output if DEBUG
    return {} if output.empty?
    JSON.parse(output)
  end

  def create_parent_job_return_id(limit, noop)
    p = {
      action: 'set_parent_job',
      params: {
        tube: 'tube-1',
        body: (0...8).map { (65 + rand(26)).chr }.join
      }
    }
    if limit
      p[:params][:limit] = limit.to_i
    end

    if noop
      p[:params][:noop] = true
    end
    output = send_to_server(p)
    return output["job"]["id"]
  end

  def create_parent_job_merge(merge_data)
    p = {
      action: 'set_parent_job',
      params: {
        tube: 'tube-1',
        body: (0...8).map { (65 + rand(26)).chr }.join
      }
    }

    p[:params].merge!(merge_data)
    output = send_to_server(p)
    return output["job"]["id"]
  end


  def put(val = nil, merge_data = {})
    p = {
      action: 'put',
      params: {
        tube: 'tube-1',
        body: val || (0...8).map { (65 + rand(26)).chr }.join
      }
    }

    p[:params].merge!(merge_data)
    send_to_server(p)
  end

  def delete(job_id)
    p = {
      action: 'delete',
      params: {
        job_id: job_id
      }
    }
    send_to_server(p)
  end

  def done(job_id)
    p = {
      action: 'done',
      params: {
        job_id: job_id
      }
    }
    send_to_server(p)
  end


  def get_return_id
    output = get
    return output["job"]["id"]
  end

  def get
    p = {
      action: 'get',
      params: {
        tube: 'tube-1'
      }
    }
    output = send_to_server(p)
    output
  end

  def stats
   p = {
     action: 'stats',
     params: {
       tube: 'tube-1'
     }
   }
   output = send_to_server(p)
   puts output.inspect if DEBUG
   output
  end

  def put_get_delete
    put
    out = get
    job_id = out['job']['id']
    delete(job_id)
  end

  def get_set_done
    out = get
    job_id = out['job']['id']
    done(job_id)
  end


end
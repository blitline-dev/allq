module AllQ
  class KickHandler < BaseClientHandler
    JOB_ID_DIVIDER        = ","
    # -------------------------------------------------
    # Peek needs to look through all queues, not just a
    # sampled one. It should iterator until it finds
    # one and return in. Otherwise nothing to return
    # -------------------------------------------------
    def process(parsed_data)
      result_hash = Hash(String, JSON::Any)
      full_job_id = parsed_data["params"]["job_id"]
      tube = parsed_data["params"]["tube"]
      vals = full_job_id.to_s.split(JOB_ID_DIVIDER)
      connection_id = vals[0].to_s
      # -- Run through connections...
      server_client = @server_connections.get(connection_id)
      output = server_client.send_string(parsed_data)
      return output || "{}"
    end
  end
end

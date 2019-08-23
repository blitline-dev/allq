require "http/client"
require "json"

class Facade
  def initialize
    @allq_client = ENV["ALLQ_CLIENT_LOCALHOST"]? ? ENV["ALLQ_CLIENT_LOCALHOST"].to_s : "127.0.0.1:8090"
    @action_count = 0
    @final_stats = Hash(String, Hash(String, Int32)).new
  end

  def load(remote_url = nil)
    if remote_url
      response = HTTP::Client.get remote_url + "/stats"
    else
      response = HTTP::Client.get "http://#{@allq_client}/stats"
    end
    body = response.body
    json_results = JSON.parse(body)
    aggregate_data(json_results)
    return json_results
  end

  def action_count
    @action_count
  end

  def stats
    @final_stats
  end

  def aggregate_data(raw_stats)
    action_counts = Array(Int32).new

    raw_stats.as_a.each do |agg|
      @action_count += agg["action_count"].as_i
      agg["stats"].as_a.each do |tube_ref|
        name = tube_ref["tube"].as_s
        @final_stats[name] = Hash(String, Int32).new unless @final_stats[name]?
        @final_stats[name]["ready"] = nil_to_val(@final_stats[name]["ready"]?) + tube_ref["ready"].as_i
        @final_stats[name]["reserved"] = nil_to_val(@final_stats[name]["reserved"]?) + tube_ref["reserved"].as_i
        @final_stats[name]["delayed"] = nil_to_val(@final_stats[name]["delayed"]?) + tube_ref["delayed"].as_i
        @final_stats[name]["buried"] = nil_to_val(@final_stats[name]["buried"]?) + tube_ref["buried"].as_i
        @final_stats[name]["parents"] = nil_to_val(@final_stats[name]["parents"]?) + tube_ref["parents"].as_i
      end
    end
  end

  def nil_to_val(val)
    if val.nil?
      return 0
    else
      return val.to_i
    end
  end
end

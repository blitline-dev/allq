require "http/client"
require "json"

class Facade
  struct SplitStat
    property stat : Hash(String, Hash(String, Int32)),
      server_name : String

    def initialize(@stat, @server_name)
    end
  end

  def initialize
    @allq_client = ENV["ALLQ_CLIENT_LOCALHOST"]? ? ENV["ALLQ_CLIENT_LOCALHOST"].to_s : "127.0.0.1:8090"
    @action_count = 0
    @final_stats = Hash(String, Hash(String, Int32)).new
    @split_stats = Array(SplitStat).new
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

  def split_stats : Array(SplitStat)
    @split_stats
  end

  def build_split_stat(stats_node, server_name)
    stat = Hash(String, Hash(String, Int32)).new
    stats_node["stats"].as_a.each do |tube_ref|
      name = tube_ref["tube"].as_s
      stat[name] = Hash(String, Int32).new
      stat[name]["ready"] = tube_ref["ready"].as_i
      stat[name]["reserved"] = tube_ref["reserved"].as_i
      stat[name]["delayed"] = tube_ref["delayed"].as_i
      stat[name]["buried"] = tube_ref["buried"].as_i
      stat[name]["parents"] = tube_ref["parents"].as_i
    end
    return SplitStat.new(stat, server_name)
  end

  def aggregate_data(raw_stats)
    action_counts = Array(Int32).new
    puts raw_stats.inspect
    raw_stats.as_a.each do |agg|
      @action_count += agg["action_count"].as_i
      server_name = agg["server_name"].to_s
      @split_stats << build_split_stat(agg, server_name)
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

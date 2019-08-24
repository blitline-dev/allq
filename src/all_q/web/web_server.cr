require "./src/*"
require "kemal"

public_folder "src/all_q/web/public/"

get "/" do
  facade = Facade.new
  facade.load
  stats = facade.stats
  puts stats.inspect
  action_count = facade.action_count
  render "src/all_q/web/src/views/index.ecr", "src/all_q/web/src/views/layout.ecr"
end

get "/split" do
  facade = Facade.new
  facade.load
  root_stats = facade.split_stats
  action_count = facade.action_count
  render "src/all_q/web/src/views/index_split.ecr", "src/all_q/web/src/views/layout.ecr"
end

Kemal.run

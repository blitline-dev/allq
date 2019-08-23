require "./src/*"
require "kemal"

public_folder "src/all_q/web/public/"

get "/" do
  facade = Facade.new
  facade.load
  stats = facade.stats
  action_count = facade.action_count
  render "src/all_q/web/src/views/index.ecr"
end

Kemal.run

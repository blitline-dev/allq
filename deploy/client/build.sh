ruby -i -pe 'gsub(/version=(\d+)/) {|m| "version=#{$1.to_i + 1}" }' Dockerfile
sudo docker build --rm=true -t local_allq_client .

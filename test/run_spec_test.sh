echo "Running against localhost:8090, either Docker or live crystal"
docker run -it -v /var/run/docker.sock:/var/run/docker.sock -v /Volumes/usb/crystal/all_q/test/ruby:/ruby --network=host allq-ruby-test /bin/bash -c "cd /ruby && rspec"


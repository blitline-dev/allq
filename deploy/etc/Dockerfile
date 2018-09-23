FROM blitline/allq:client_latest

RUN apt-get update
RUN which ruby

RUN gem install etcdv3

ENV version=27
COPY ruby_updater.rb ruby_updater.rb

ENTRYPOINT ["/opt/rubies/ruby-2.5.1/bin/ruby", "ruby_updater.rb"]
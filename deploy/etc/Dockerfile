FROM ruby:2.5-alpine

RUN which ruby
RUN gem install etcdv3

ENV version=32
COPY ruby_updater.rb ruby_updater.rb

ENTRYPOINT ["/usr/local/bin/ruby", "ruby_updater.rb"]
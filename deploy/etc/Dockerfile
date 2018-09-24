FROM ruby:2.5

RUN which ruby
RUN gem install etcdv3

ENV version=34
COPY ruby_updater.rb ruby_updater.rb

ENTRYPOINT ["/usr/local/bin/ruby", "ruby_updater.rb"]
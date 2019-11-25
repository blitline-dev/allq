FROM ruby:2.5

RUN which ruby

ENV version=41
COPY ruby_updater.rb ruby_updater.rb

ENTRYPOINT ["/usr/local/bin/ruby", "ruby_updater.rb"]

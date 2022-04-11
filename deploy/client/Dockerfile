FROM crystallang/crystal:1.3.2
RUN echo "touch4"
RUN apt-get update
RUN apt-get install -y git nano wget

#install dependency
RUN apt-get install -y libtool pkg-config build-essential autoconf automake uuid-dev


RUN apt-get install -y  libsodium-dev libzmq3-dev
RUN apt-get install -y socat curl


RUN echo "deb https://apt.fullstaqruby.org ubuntu-20.04 main" > "/etc/apt/sources.list.d/fullstaq-ruby.list"
RUN curl -SLfO https://raw.githubusercontent.com/fullstaq-labs/fullstaq-ruby-server-edition/main/fullstaq-ruby.asc \
  && apt-key add fullstaq-ruby.asc \
  && apt update \
  && apt install -y fullstaq-ruby-common \
  && apt install -y fullstaq-ruby-2.6

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/fullstaq-ruby/versions/2.6/bin

RUN ruby -v

RUN gem install bundler -v 1.16.3 && gem update --system
RUN apt-get dist-upgrade -y
ENV version=180

RUN cd /

RUN git clone -b master https://github.com/blitline-dev/allq.git
RUN cd allq && /usr/bin/shards && crystal build src/all_q/client/client.cr --release -o allq_client
RUN cd allq && chmod 777 allq_client && mv allq_client /usr/bin/allq_client
RUN git clone https://github.com/blitline-dev/allq_cli.git
RUN cd allq_cli && bundle install && bundle update

COPY http_stat.sh http_stat.sh
COPY stats.sh stats.sh
COPY up.sh up.sh
COPY cli.sh cli.sh
COPY healthcheck.sh healthcheck.sh
RUN chmod 777 http_stat.sh
RUN chmod 777 stats.sh
RUN chmod 777 cli.sh
RUN chmod 777 up.sh
RUN chmod 777 healthcheck.sh 

ENTRYPOINT ["/up.sh"]



FROM crystallang/crystal:0.35.1
RUN echo "touch4"
RUN apt-get update
RUN apt-get install -y git nano wget

#install dependency
RUN apt-get install -y libtool pkg-config build-essential autoconf automake uuid-dev


RUN apt-get install -y  libsodium-dev libzmq3-dev
RUN apt-get install -y socat

# install ruby
RUN wget -O ruby-install-0.7.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.7.0.tar.gz
RUN tar -xzvf ruby-install-0.7.0.tar.gz
RUN  cd ruby-install-0.7.0/ &&  make install
RUN ruby-install ruby 2.5.3
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/rubies/ruby-2.5.1/lib:/opt/rubies/ruby-2.5.3/bin

RUN ruby -v

RUN gem install bundler -v 1.16.3 && gem update --system
RUN apt-get install -y curl


ENV version=148

RUN cd /
COPY stats.sh stats.sh
COPY cli.sh cli.sh
RUN chmod 777 stats.sh
RUN chmod 777 cli.sh
RUN git clone -b zero https://blitline-dev:***REMOVED***@github.com/blitline-dev/allq.git
RUN cd allq && /usr/bin/shards && crystal build src/all_q/client/client.cr --release -o allq_client
RUN cd allq && chmod 777 allq_client && mv allq_client /usr/bin/allq_client
RUN git clone https://github.com/blitline-dev/allq_cli.git
RUN cd allq_cli && bundle install && bundle update

ENTRYPOINT ["/usr/bin/allq_client"]



FROM crystallang/crystal
RUN echo "touch"
RUN apt-get update
RUN apt-get install -y git nano wget

#install dependency
RUN apt-get install -y libtool pkg-config build-essential autoconf automake uuid-dev

RUN echo "deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/Debian_9.0/ /" >> /etc/apt/sources.list
RUN cat /etc/apt/sources.list

RUN wget -nv https://download.opensuse.org/repositories/network:messaging:zeromq:git-stable/Debian_Next/Release.key -O Release.key
RUN apt-key add - < Release.key
RUN apt-get install -y libzmq3-dev
RUN apt-get install -y socat

# install ruby
RUN wget -O ruby-install-0.7.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.7.0.tar.gz
RUN tar -xzvf ruby-install-0.7.0.tar.gz
RUN  cd ruby-install-0.7.0/ &&  make install
RUN ruby-install ruby 2.5
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/rubies/ruby-2.5.1/lib:/opt/rubies/ruby-2.5.1/bin
RUN ruby -v
RUN gem install bundler

ENV version=77

RUN cd /
COPY stats.sh stats.sh
RUN chmod 777 stats.sh
RUN git clone https://blitline-dev:CHB4URXWTh@github.com/blitline-dev/allq.git
RUN cd allq && /usr/bin/shards && crystal build src/all_q/client/client.cr --release -o allq_client
RUN cd allq && chmod 777 allq_client && mv allq_client /usr/bin/allq_client


ENTRYPOINT ["/usr/bin/allq_client"]



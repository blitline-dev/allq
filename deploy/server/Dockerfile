FROM crystallang/crystal
RUN apt-get update
RUN apt-get install -y git nano wget  libsodium-dev
#RUN wget http://download.zeromq.org/zeromq-4.0.5.tar.gz

#unpack tarball package
#RUN tar xvzf zeromq-4.0.5.tar.gz

#install dependency
RUN apt-get install -y libtool pkg-config build-essential autoconf automake uuid-dev

#in zeromq dir
#RUN cd zeromq-4.0.5 && ./configure && make install && ldconfig && ldconfig -p | grep zmq

RUN echo "deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/Debian_9.0/ ./" >> /etc/apt/sources.list
RUN wget https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/Debian_9.0/Release.key -O- | apt-key add
RUN apt-get install -y libzmq3-dev

RUN echo "version=1.0.13"
RUN git clone https://blitline-dev:CHB4URXWTh@github.com/blitline-dev/allq.git
RUN cd allq && /usr/bin/shards && crystal build src/all_q/server/server.cr --release -o allq_server
RUN cd allq && chmod 777 allq_server && mv allq_server /usr/bin/allq_server

ENTRYPOINT ["allq_server"]

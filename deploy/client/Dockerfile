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

ENV SERVER_IP ec2-54-221-119-214.compute-1.amazonaws.com
ENV SERVER_PORT 7788

RUN echo "version=1.0.12"
RUN git clone https://blitline-dev:CHB4URXWTh@github.com/blitline-dev/allq.git
RUN cd allq && /usr/bin/shards && crystal build src/all_q/client/client.cr --release -o allq_client
RUN cd allq && chmod 777 allq_client && mv allq_client /usr/bin/allq_client

ENTRYPOINT ["allq_client"]
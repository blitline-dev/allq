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

ENV version=39
RUN git clone https://blitline-dev:CHB4URXWTh@github.com/blitline-dev/allq.git
RUN cd allq && /usr/bin/shards && crystal build src/all_q/client/client.cr --release -o allq_client
RUN cd allq && chmod 777 allq_client && mv allq_client /usr/bin/allq_client

ENTRYPOINT ["/usr/bin/allq_client"]

FROM crystallang/crystal
RUN apt-get update && apt-get -y upgrade
RUN echo "touch5"

RUN apt-get update
RUN apt-get install -y git nano wget

#install dependency
RUN apt-get install -y libtool pkg-config build-essential autoconf automake uuid-dev

RUN echo "deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/Debian_9.0/ /" >> /etc/apt/sources.list
RUN cat /etc/apt/sources.list

RUN apt-get -y upgrade
RUN wget -nv https://download.opensuse.org/repositories/network:messaging:zeromq:git-stable/Debian_Next/Release.key -O Release.key
RUN apt-key add - < Release.key
RUN apt-get install -y  libsodium-dev libzmq5-dev
RUN apt-get install -y socat
RUN apt-get -y upgrade

ENV VERSION=124
RUN echo $(crystal -v)
RUN apt-get update && apt-get -y upgrade
RUN git clone https://blitline-dev:***REMOVED***@github.com/blitline-dev/allq.git
RUN cd allq && shards
RUN cd allq && sed -i 's/FFI::MemoryPointer.*$/" " * 41/g' lib/zeromq/src/zeromq/util.cr && sed -i 's/\.read_string//g' lib/zeromq/src/zeromq/util.cr

RUN echo $(crystal -v)
RUN cd allq && crystal build src/all_q/server/server.cr --release -o allq_server


RUN cd allq && chmod 777 allq_server && mv allq_server /usr/bin/allq_server

ENTRYPOINT ["/usr/bin/allq_server"]

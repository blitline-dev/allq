FROM crystallang/crystal:0.35.1
RUN echo "touch5"

RUN apt-get update


RUN apt-get install -y git nano wget


RUN apt-get install -y  libsodium-dev libzmq3-dev
RUN apt-get install -y socat

ENV VERSION=127
RUN echo $(crystal -v)
ENV VERSION=128

RUN git clone https://blitline-dev:CHB4URXWTh@github.com/blitline-dev/allq.git
RUN cd allq && shards
RUN cd allq && sed -i 's/FFI::MemoryPointer.*$/" " * 41/g' lib/zeromq/src/zeromq/util.cr && sed -i 's/\.read_string//g' lib/zeromq/src/zeromq/util.cr

RUN echo $(crystal -v)
RUN cd allq && crystal build src/all_q/server/server.cr --release -o allq_server


RUN cd allq && chmod 777 allq_server && mv allq_server /usr/bin/allq_server
RUN apt-get -y upgrade

ENTRYPOINT ["/usr/bin/allq_server"]

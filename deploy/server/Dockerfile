FROM crystallang/crystal:1.3.2
RUN echo "touch6"

RUN apt-get update

RUN apt-get install -y git nano wget


RUN apt-get install -y  libsodium-dev libzmq3-dev
RUN apt-get install -y socat

ENV VERSION=127
RUN echo $(crystal -v)
RUN apt-get dist-upgrade -y
ENV VERSION=132

RUN git clone -b master https://github.com/blitline-dev/allq.git
RUN cd allq && shards install
RUN cd allq && sed -i 's/FFI::MemoryPointer.*$/" " * 41/g' lib/zeromq/src/zeromq/util.cr && sed -i 's/\.read_string//g' lib/zeromq/src/zeromq/util.cr

RUN echo $(crystal -v)
RUN cd allq && crystal build src/all_q/server/server.cr --release -o allq_server


RUN cd allq && chmod 777 allq_server && mv allq_server /usr/bin/allq_server

ENTRYPOINT ["/usr/bin/allq_server"]

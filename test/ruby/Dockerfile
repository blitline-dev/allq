FROM ruby:2.5.5
RUN echo "v=1.0.001"

RUN apt-get update
COPY Gemfile ./Gemfile
RUN bundle install

RUN apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common \
   && curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
   add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable" && \
   apt-get update && \
   apt-get -y install docker-ce







COPY spec ./spec


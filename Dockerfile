#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM ubuntu:18.04

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y apt-utils curl zip unzip wget python && \
  rm -rf /var/lib/apt/lists/* && \
  curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz && \
  mkdir -p /usr/local/gcloud && \
  tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz && \
  bash /usr/local/gcloud/google-cloud-sdk/install.sh 



ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

CMD ["bash"]
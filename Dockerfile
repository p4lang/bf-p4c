FROM ubuntu:16.04

MAINTAINER bfn-docker <bfn-docker@barefootnetworks.com>

ENV DEBIAN_FRONTEND noninteractive

ENV P4C_DEPS automake \
             bison \
             build-essential \
             flex \
             g++ \
             libboost-dev \
             libboost-iostreams-dev \
             libfl-dev \
             libgc-dev \
             libgmp-dev \
             libtool \
             pkg-config \
             python-ipaddr \
             python-pip \
             python-scapy \
             python-yaml \
             tcpdump

ENV P4C_RUNTIME_DEPS cpp \
                     libboost-iostreams1.58.0 \
                     libgc1c2 \
                     libgmp10 \
                     libgmpxx4ldbl \
                     python

ENV PROTOBUF_DEPS curl \
                  git \
                  unzip

RUN apt-get update && \
    apt-get install -y $P4C_DEPS $P4C_RUNTIME_DEPS
RUN apt-get install -y $PROTOBUF_DEPS

# Default to using 2 make jobs, which is a good default for CI. If you're
# building locally or you know there are more cores available, you may want to
# override this.
ARG MAKEFLAGS=-j2

# install protobuf
WORKDIR /bfn/
RUN git clone --recursive https://github.com/google/protobuf.git && \
    cd protobuf && \
    git checkout v3.0.2 && \
    ./autogen.sh && \
    ./configure && \
    make && make install-strip && \
    ldconfig

COPY . /bfn/bf-p4c-compilers/
WORKDIR /bfn/bf-p4c-compilers
RUN pip install pyinstaller
RUN ./bootstrap_bfn_compilers.sh && \
    cd p4c/build && \
    make && make install-strip && \
    cd ../.. && \
    cd bf-asm/build && \
    make && make install-strip

WORKDIR /bfn
RUN rm -rf /bfn/protobuf

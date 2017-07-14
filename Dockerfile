FROM barefootnetworks/model:latest

MAINTAINER bfn-docker <bfn-docker@barefootnetworks.com>

ENV DEBIAN_FRONTEND noninteractive

ENV P4C_DEPS automake \
             bison \
             build-essential \
             cmake \
             flex \
             g++ \
             libboost-dev \
             libboost-graph-dev \
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

RUN apt-get update && \
    apt-get install -y $P4C_DEPS
RUN pip install pyinstaller

# Default to using 2 make jobs, which is a good default for CI. If you're
# building locally or you know there are more cores available, you may want to
# override this.
ARG MAKEFLAGS=-j2

COPY . /bfn/bf-p4c-compilers/
WORKDIR /bfn/bf-p4c-compilers
RUN pip install pyinstaller
RUN ./bootstrap_bfn_compilers.sh -DCMAKE_BUILD_TYPE=RELEASE && \
    cd build && \
    make && make install
WORKDIR /bfn/bf-p4c-compilers
RUN rm -rf build

# install PTF for testing
WORKDIR /bfn/
RUN git clone https://github.com/p4lang/ptf.git && \
    cd ptf && \
    python setup.py install && \
    cd /bfn && \
    rm -rf ptf

# cleanup space on the image
RUN apt-get clean -y && apt-get autoclean -y

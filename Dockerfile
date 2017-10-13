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
             sudo \
             tcpdump

RUN apt-get update && \
    apt-get install -y $P4C_DEPS
RUN pip install pyinstaller==3.2.1

# Default to using 2 make jobs, which is a good default for CI. If you're
# building locally or you know there are more cores available, you may want to
# override this.
ARG MAKEFLAGS=-j2

# Use 'test' if you wish to keep the build artifacts
ARG IMAGE_TYPE=release

# testing dependencies
RUN apt-get install -y net-tools
WORKDIR /bfn/
RUN git clone https://github.com/p4lang/ptf.git && \
    cd ptf && \
    python setup.py install && \
    cd /bfn && \
    rm -rf ptf

RUN pip install ply
COPY . /bfn/bf-p4c-compilers/
COPY scripts/ptf_hugepage_setup.sh /bfn/ptf_hugepage_setup.sh
COPY scripts/docker_entry_point.sh /bfn/docker_entry_point.sh
WORKDIR /bfn/bf-p4c-compilers
RUN ./bootstrap_bfn_compilers.sh -DCMAKE_BUILD_TYPE=RELEASE && \
    cd build && \
    make && make install
WORKDIR /bfn/
RUN (test "$IMAGE_TYPE" = "release" && rm -rf bf-p4c-compilers) || \
    (test "$IMAGE_TYPE" = "test")

# cleanup space on the image
RUN apt-get clean -y && apt-get autoclean -y

# setup huge pages
ENTRYPOINT ["/bfn/docker_entry_point.sh"]

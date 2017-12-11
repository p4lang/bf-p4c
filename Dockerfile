FROM barefootnetworks/model:latest

MAINTAINER bfn-docker <bfn-docker@barefootnetworks.com>
ENV DEBIAN_FRONTEND noninteractive

ENV P4C_DEPS autoconf \
             automake \
             bison \
             build-essential \
             flex \
             g++ \
             libboost-dev \
             libboost-graph-dev \
             libboost-iostreams-dev \
             libfl-dev \
             libgc-dev \
             libgmp-dev \
             libtool \
             python-dev \
             python-pip


ENV P4C_RUNTIME_DEPS cpp \
                     cmake \
                     libboost-iostreams1.58.0 \
                     libgc1c2 \
                     libgmp10 \
                     libgmpxx4ldbl \
                     pkg-config \
                     python-ipaddr \
                     python-scapy \
                     python-setuptools \
                     python-yaml \
                     sudo \
                     tcpdump


RUN apt-get update && \
    apt-get install -y $P4C_DEPS $P4C_RUNTIME_DEPS
RUN pip install pyinstaller==3.2.1

# Default to using 2 make jobs, which is a good default for CI. If you're
# building locally or you know there are more cores available, you may want to
# override this.
ARG MAKEFLAGS=-j2

# Use 'test' if you wish to keep the build artifacts
ARG IMAGE_TYPE=release

# testing dependencies
RUN apt-get install -y net-tools

RUN pip install ply
COPY . /bfn/bf-p4c-compilers/
COPY scripts/ptf_hugepage_setup.sh /bfn/ptf_hugepage_setup.sh
COPY scripts/docker_entry_point.sh /bfn/docker_entry_point.sh
WORKDIR /bfn/bf-p4c-compilers
ENV LDFLAGS="-Wl,-s"
RUN /usr/local/bin/ccache --zero-stats && \
    ./bootstrap_bfn_compilers.sh -DENABLE_P4C_GRAPHS=OFF \
                                 -DENABLE_BMV2=OFF -DENABLE_P4TEST=OFF \
                                 -DENABLE_EBPF=OFF -DENABLE_STF2PTF=OFF \
                                 && \
    cd build && \
    make && \
    make install && \
    /usr/local/bin/ccache -p --show-stats && \
    pip uninstall -y pyinstaller && \
    apt-get purge -y $P4C_DEPS && \
    apt-get autoremove --purge -y && \
    rm -rf ~/.cache/* ~/.ccache/* /var/cache/apt/* /var/lib/apt/lists/* && \
    rm -rf bf-asm/walle/build/* && \
    rm -rf bf-asm/simple_test_harness/jbay_test_harness && \
    find . -name '*.o' -type f -delete && \
    find . -name '*.a' -type f -delete && \
    find . -name '*.json' -type f -delete

WORKDIR /bfn/
RUN (test "$IMAGE_TYPE" = "release" && rm -rf bf-p4c-compilers) || \
    (test "$IMAGE_TYPE" = "test")

# cleanup space on the image
RUN apt-get clean -y && apt-get autoclean -y

# setup huge pages
ENTRYPOINT ["/bfn/docker_entry_point.sh"]

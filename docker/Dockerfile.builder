# this docker file is not intended to be invoked directly, instead, please use
# the Makefile in this directory
# all the ARG variables are set using the Makefile
ARG DOCKER_PROJECT
ARG P4FACTORY_PROJECT
ARG P4FACTORY_IMAGE

FROM ${P4FACTORY_PROJECT}/${P4FACTORY_IMAGE} AS base

MAINTAINER bfn-docker <bfn-docker@barefootnetworks.com>

# Set up environment variables.

# Set things up for distcc.
ENV DISTCC_IO_TIMEOUT="450"

# Set up Intel proxies.
ENV http_proxy='http://proxy-dmz.intel.com:911'
ENV https_proxy='http://proxy-dmz.intel.com:912'
ENV ftp_proxy='http://proxy-dmz.intel.com:21'
ENV socks_proxy='proxy-dmz.intel.com:1080'
ENV no_proxy='intel.com,*.intel.com,localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12'
ENV ALL_PROXY='socks5://proxy-dmz.intel.com'

ENV PYTHONPATH="/p4factory/install/lib/python3.8/site-packages"

# Setup PTF environment (Use bf-pktpy by default)
ENV PKTPY='True'

###############################################################################
FROM base AS p4factory_build

ARG P4FACTORY_GIT_REV
ARG BUILD_JOBS=4
LABEL P4FACTORY_GIT_REV=${P4FACTORY_GIT_REV}

# checkout the specific revision of p4factory & init its submodules
# we use the ssh access to github for all clones because the http proxy is
# somehow broken for git
RUN git clone git@github.com:intel-restricted/networking.switching.barefoot.p4factory /p4factory && \
    cd /p4factory && \
    git checkout ${P4FACTORY_GIT_REV} && \
    git config --global url."git@github.com:".insteadOf "https://github.com/" && \
    git submodule update -i --recursive --depth 1 --single-branch -j ${BUILD_JOBS}

# Build and install to /usr/local to avoid problems with binary and library lookups
RUN mkdir /p4factory/build
WORKDIR /p4factory/build
RUN cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=Release \
        -DCOMPILER=OFF \
        -DMODEL=ON \
        -DPREBUILT-COMPILER=OFF \
        -DPREBUILT-MODEL=OFF \
        -DP4RT=ON \
        -DMIMIC_ENABLE_LOGGING=ON \
        -DTOFINO=OFF && \
    make -j ${BUILD_JOBS} && \
    make -j ${BUILD_JOBS} install

###############################################################################
FROM p4factory_build AS p4factory_build_clean

RUN rm -rf /p4factory/.git \
           /p4factory/submodules \
           /p4factory/build

FROM base AS p4factory

# This is a bit dirty, but we want to avoid taking all the layers of the build
# image by reusing it directly. Since both this image and p4factory_build_clean
# are build on the same basis and this image does nothing with /usr/local
# inbetween, this should be quite safe
COPY --from=p4factory_build_clean \
        /usr/local \
        /usr/local
COPY --from=p4factory_build_clean \
        /p4factory \
        /p4factory

# Install simple_test_harness to /usr/local
COPY --from=p4factory_build \
        /p4factory/build/submodules/model/tests/simple_test_harness/*_test_harness \
        /usr/local/bin/

# Create symlink /usr/local -> /p4factory/install (for compatibilty)
RUN ln -s /usr/local /p4factory/install

# Fix p4studio dependencies broken by upgrading python3/pip3 while installing build into /usr/local/
RUN pip3 install -r /p4factory/release/target-toplevel-files/p4studio/third_party/requirements.txt

###############################################################################
FROM p4factory AS builder

RUN rm -rf /root/.ssh/id_*

# Set to true to setup CI-specific configuration (e.g. path to ccache directory)
ARG BUILDING_IN_CI="true"

# Copy directories needed to environment preparation separately to
# allow env preparation to be cached.
WORKDIR /bfn/bf-p4c-compilers
ADD docker docker
ADD scripts scripts
ADD p4-tests/p4testutils p4-tests/p4testutils

RUN docker/docker_prepare_env.sh

ARG GIT_REV
LABEL BUILDER_GIT_REV=$GIT_REV
ARG P4FACTORY_GIT_REV
LABEL P4FACTORY_GIT_REV=${P4FACTORY_GIT_REV}

CMD ["/bin/bash"]
ENTRYPOINT ["/bfn/docker_entry_point.sh"]

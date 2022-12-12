#!/usr/bin/env bash

set -Eeuxo pipefail

MAKEFILE=${1:-Makefile}
P4FACTORY_BRANCH=${2:-master}
P4C_BRANCH=${3:-master}
P4C_BRANCH_TAG=$(echo $P4C_BRANCH | sed 's,/,--,g')

P4FACTORY_GIT_REV=${4:-}
if [[ -z ${P4FACTORY_GIT_REV} ]]; then
    P4FACTORY_GIT_REV=$(git ls-remote git@github.com:intel-restricted/networking.switching.barefoot.p4factory.git refs/heads/${P4FACTORY_BRANCH} | cut -f1)
fi
BUILDER_TAG=amr-registry.caas.intel.com/bxd-sw/bf-p4c-builder:${P4C_BRANCH_TAG}
make -f${MAKEFILE} builder P4FACTORY_GIT_REV=${P4FACTORY_GIT_REV} BUILDER_TAG=${BUILDER_TAG}
docker push ${BUILDER_TAG}
docker pull ${BUILDER_TAG}
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${BUILDER_TAG})
BUILDER_ID=$(echo $DIGEST | sed 's,^.*\(bf-p4c-builder\),\1,')

sed -i -e 's,^\(P4FACTORY_GIT_REV ?= \).*$,\1'${P4FACTORY_GIT_REV}',' \
       -e 's,^\(BUILDER_IMAGE ?= \).*$,\1'${BUILDER_ID}',' \
       ${MAKEFILE}

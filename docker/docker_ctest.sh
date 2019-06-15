#! /bin/bash

# Run a set of tests by pulling a docker image identified by DOCKER_TAG

usage() {
    echo $1
    echo "Usage: $0 --suite <regex> --exclude <regex>"
    echo "  --suite <regex>: a regex that selects the tests"
    echo "  --exclude <regex>: a regex that excludes tests"
    echo "  --exclude_label <regex>: a regex that exclues tests by a label"
}

TEST_SUITE="none"
TEST_EXCLUDE="none"
TEST_EXCLUDE_LABLE="none"
while [ $# -gt 0 ]; do
    case $1 in
        --suite)
            if [ -z "$2" ]; then
                usage "Error: --suite needs to be specified"
                exit 1
            fi
            TEST_SUITE="$2"
            shift;
            ;;
        --exclude)
            TEST_EXCLUDE="$2"
            if [ -z "$2" ]; then
                usage "Error: --exclude needs to be specified"
                exit 1
            fi
            ;;
        --exclude_label)
            TEST_EXCLUDE_LABEL="$2"
            ;;
        -h|--help)
            usage ""
            exit 0
            ;;
    esac
    shift
done

if [[ $TEST_SUITE = "none" || $TEST_EXCLUDE = "none" ]]; then
    usage "Error: both --suite and --exclude must be specified"
    exit 1
fi

docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
export DOCKER_TAG=$(if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then \
                        echo $TRAVIS_COMMIT; \
                    else echo $TRAVIS_PULL_REQUEST_SHA; fi)
echo "DOCKER_TAG=$DOCKER_TAG"
# Can directly pull, because the image will be available, we already waited
#/bfn/bf-p4c-compilers/docker/docker_pull.py \
#    --image barefootnetworks/bf-p4c-compilers:$DOCKER_TAG \
#    --timeout $PULL_TIMEOUT
docker pull barefootnetworks/bf-p4c-compilers:$DOCKER_TAG

ctest_with_opts="ctest -R $TEST_SUITE -E $TEST_EXCLUDE"
if [[ $TEST_EXCLUDE_LABEL != "none" ]]; then
    ctest_with_opts="$ctest_with_opts -LE $TEST_EXCLUDE_LABEL"
fi

echo "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c \
       -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE=true -e MAKEFLAGS \
       barefootnetworks/bf-p4c-compilers:$DOCKER_TAG \
       $ctest_with_opts"
docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c \
       -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE=true -e MAKEFLAGS \
       barefootnetworks/bf-p4c-compilers:$DOCKER_TAG \
       $ctest_with_opts

/**
 * Libraries contain reusabile snippets that can be reused across multiple projects.
 */
@Library('bf-jenkins-utils@master')_

node {
    // kill any previous runs of the same branch that may be in progress
    stopPreviousRuns(this)
}

// Intel CaaS (AMR)
DOCKER_CREDENTIALS = "bfndocker-caas"
DOCKER_REGISTRY = "amr-registry.caas.intel.com"
DOCKER_PROJECT = "${DOCKER_REGISTRY}/bxd-sw"

BRANCH_ID = "${env.BRANCH_NAME.toLowerCase().replaceAll("/","_")}"

node ('compiler-nodes') {
    // Clean workspace before doing anything
    sh "sudo chmod -R 777 ."
    deleteDir()
    ansiColor('xterm') {
        timestamps {

            stage ('Checkout') {
                echo 'Checking out bf-p4c-compilers'
                checkout scm
                bf_p4c_compilers_rev = sh (
                    script: 'git rev-parse HEAD',
                    returnStdout: true
                ).trim()
                bf_p4c_compilers_rev_short = sh (
                    script: 'git rev-parse --short HEAD',
                    returnStdout: true
                ).trim()
                echo "Using bf-p4c-compilers:${bf_p4c_compilers_rev}"
                sh 'git log -1 --stat'
            }

            stage ('Setup build') {
                echo "Initializing bf-p4c-compilers submodules"
                sh "git submodule update --init --recursive"
            }

            stage ('Build') {
                echo 'Building Docker image'
                sh """
                    docker build \
                        --pull \
                        -f docker/Dockerfile.tofino \
                        -t bf-p4c-compilers_doc_${BRANCH_ID} \
                        --build-arg DOCKER_PROJECT=${DOCKER_PROJECT} \
                        --build-arg MAKEFLAGS=j16 \
                        --build-arg IMAGE_TYPE=doc \
                        .
                """
            }

            stage ('Publish') {
                echo 'Extracting documentation'
                def curr_pwd = pwd()
                sh """
                    mkdir -p doc
                    docker run --rm \
                        -w /bfn/bf-p4c-compilers/build \
                        -v ${curr_pwd}/doc:/mnt \
                        bf-p4c-compilers_doc_${BRANCH_ID} \
                            tar czf /mnt/html.tar.gz html
                """

                echo 'Archiving artifact'
                archiveArtifacts(
                    artifacts: 'doc/html.tar.gz'
                )
            }

        }
    }
}

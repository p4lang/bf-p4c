/**
 * Libraries contain reusabile snippets that can be reused across multiple projects.
 */
@Library('bf-jenkins-utils@master')_

properties([
     buildDiscarder(BuildHistoryManager([
     [
         matchAtMost: 10,
         continueAfterMatch: false
     ],
     [
         actions: [DeleteBuild()]
     ]
     ])),
     parameters([
        booleanParam( name: 'UBSAN',                      defaultValue: (boolean)(env.JOB_NAME =~ /sanitizers/),                                                                    description: 'Choose whether to use Undefined Behavior Sanitizer.', ),
        booleanParam( name: 'ASAN',                       defaultValue: (boolean)(env.JOB_NAME =~ /sanitizers/),                                                                    description: 'Choose whether to use Address Sanitizer.', ),

        string(       name: 'UBSAN_OPTIONS',              defaultValue: env.JOB_NAME =~ /sanitizers/ ? 'print_stacktrace=1' : '',                                                   description: 'Options to configure Undefined Behavior Sanitizer.', ),
        string(       name: 'ASAN_OPTIONS',               defaultValue: env.JOB_NAME =~ /sanitizers/ ? 'print_stacktrace=1:halt_on_error=0:detect_leaks=0' : '',                    description: 'Options to configure Address Sanitizer.', ),

     ])
])

node {
    // kill any previous runs of the same PR that may be in progress
    stopPreviousRuns(this)
}

// Intel CaaS (AMR)
DOCKER_CREDENTIALS = "bfndocker-caas"
DOCKER_REGISTRY = "amr-registry.caas.intel.com"
DOCKER_PROJECT = "${DOCKER_REGISTRY}/bxd-sw"

def sanitizersEnabled() {
    return params.UBSAN || params.ASAN
}

node ('compiler-travis') {
    env.BUILDING_IN_CI = 'true'
    // Clean workspace before doing anything
    sh "sudo chmod -R 777 ."
    deleteDir()
    ansiColor('xterm') {
        timestamps {

            stage ('Checkout') {
                echo "This is ${env.BUILD_TAG}, ${params.ALT_PHV}"
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

                // if this is a PR, check if it is ALT-PHV related
                if (env.BRANCH_NAME && env.BRANCH_NAME.startsWith('PR-')) {
                    // check if commit resides in some ALT-PHV relate branch
                    isAltPHVBranch = sh(
                        script: "echo ${env.CHANGE_BRANCH} | grep -i 'alt.phv\\|alt.pass\\|table.first'",
                        returnStatus: true
                    )

                    // This is somewhat contrived, but there are several problems created by Jenkins:
                    // - the other branches are not fetched by default, but we need CHANGE_TARGET to be
                    //   avalable so that git merge-base works
                    // - for some reason, the branch is not actually available unless the part after : is also
                    //   provided
                    // - Jenkins sets url to http, but then it is unable to load private repos, so replace
                    //   that with ssh (for which there are keys)
                    sh "git -c url.\"git@github.com:\".insteadOf=\"https://github.com/\" fetch -n origin ${env.CHANGE_TARGET}:${env.CHANGE_TARGET}"
                    mergeBase = sh(
                        script: "git merge-base ${bf_p4c_compilers_rev} ${env.CHANGE_TARGET}",
                        returnStdout: true
                    ).trim();
                    sh "echo 'Last common commit is:'; git log -1 ${mergeBase}"

                    // check if history of this commit (from the point it
                    // diverged from source) contains mentions of alt-phv in
                    // either subject or long description of commit messages
                    isAltPHVCommit = sh(
                        script: "git log ${mergeBase}..${bf_p4c_compilers_rev} --format='%s%n%b' | tee /dev/stderr | grep -iq 'alt.phv\\|alt.pass\\|table.first'",
                        returnStatus: true
                    )
                    IS_ALT_PHV = isAltPHVBranch == 0 || isAltPHVCommit == 0
                    echo "branch ${env.CHANGE_BRANCH} [split of ${env.CHANGE_TARGET}]: isAltPHVCommit: ${isAltPHVCommit == 0}, isAltPHVBranch: ${isAltPHVBranch == 0}, IS_ALT_PHV: ${IS_ALT_PHV}"
                } else {
                    IS_ALT_PHV = false
                }

                echo "Initializing bf-p4c-compilers submodules"
                sh "git submodule update --init --recursive -j 16"
            }

            stage ('Pull image') {
                echo 'Attempting to pull existing bf-p4c-compilers Docker image'
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS}",
                    usernameVariable: "DOCKER_USERNAME",
                    passwordVariable: "DOCKER_PASSWORD"
                )]) {
                    sh """
                        docker login \
                            -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} \
                            ${DOCKER_REGISTRY}
                    """
                }
                kind = sanitizersEnabled() ? "sanitizers_" : ""
                branch = env.BRANCH_NAME ? env.BRANCH_NAME : scm.branches[0].name
                image_tag_branch = "${kind}${branch.toLowerCase()}".replace('/', '--')
                image_tag = "${image_tag_branch}_${bf_p4c_compilers_rev}"
                try {
                    // Try to pull any image of this branch first. The intermediate image build
                    // attempts to reuse docker layers from it, even if the revisions are not
                    // exactly the same.
                    sh "docker pull ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag_branch}"
                    echo "Pulled image bf-p4c-compilers:${image_tag_branch}"

                    // Then try to pull the image for this specific git revision, which
                    // might be available if pipeline is being re-run. We don't have to build the
                    // image in such case.
                    sh "docker pull ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag}"
                    image_pulled = 'true'
                    echo "Pulled image bf-p4c-compilers:${image_tag}"
                } catch (err) {
                    image_pulled = 'false'
                    echo 'Nothing pulled'
                }
            }

            stage ('Build intermediate') {
                // We want to mount ~/.ccache_bf-p4c-compilers into Docker when we
                // compile bf-p4c-compilers, but `docker build` doesn't do external
                // mounts. To work around this, we build the image in two stages.
                //
                // The first stage uses `docker build` to install dependencies and set
                // up the build environment. The second stage does the actual build in
                // a Docker container and cleans up.
                //
                // Build this image even if we've pulled image from registry successfully.
                // We may use it for nonstandard builds.

                echo 'Building intermediate Docker image'
                sh """
                    make -Cdocker build-internal-cached
                """
            }

            if (image_pulled != 'true') {
                stage ('Build final') {
                    parallel (
                        'Unified': {
                            echo 'Building final Docker image to run tests with (unified build)'
                            sh """
                                make -Cdocker build \
                                    BUILD_TAG=${image_tag} \
                                    BUILD_TAG_DEST=${DOCKER_PROJECT}/bf-p4c-compilers \
                                    BUILD_ARGS="\
                                        -e UNIFIED_BUILD=true \
                                        -e UBSAN=${params.UBSAN} \
                                        -e ASAN=${params.ASAN} \
                                        -e UBSAN_OPTIONS=${params.UBSAN_OPTIONS} \
                                        -e ASAN_OPTIONS=${params.ASAN_OPTIONS} \
                                        -e MAKEFLAGS=j20 \
                                    "
                            """
                        },

                        'Non-unified': {
                            echo 'Testing non-unified build'
                            sh """
                                make -Cdocker test-build \
                                    BUILD_ARGS="-e UNIFIED_BUILD=false -e MAKEFLAGS=j16"
                            """
                        },

                    )
                }

                stage ('Push image') {
                    echo "Pushing the built Docker image bf-p4c-compilers:${image_tag}"
                    try {
                        sh "docker push ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag}"
                        sh "docker tag ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag} \
                                       ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag_branch}"
                        sh "docker push ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag_branch}"
                    } catch (err) {
                        echo "Pushing of the built Docker image failed. Notifying the maintainers and continuing."
                        emailext subject: "${env.JOB_NAME} failed to push build Docker image",
                                    body: "Check console output at '${env.RUN_DISPLAY_URL}'",
                                    to: "vojtech.havel@intel.com,vladimir.still@intel.com,prathima.kotikalapudi@intel.com",
                                    attachLog: true
                    }
                }
            }

            // TODO: Enable Flatrock testing when ALT-PHV and/or Flatrock is more mature
            MAX_ALT_PHV = IS_ALT_PHV ? 3 : 1
            echo "testing ALT PHV for Tofino 1..${MAX_ALT_PHV}"
            // run tests from a file
            withEnv(["SANITIZERS_ENABLED=${sanitizersEnabled()}",
                     "BF_P4C_REV=${bf_p4c_compilers_rev}",
                     "IMAGE_TAG=${image_tag}",
                     "ALT_PHV_TOFINO_MAX_VERSION=${MAX_ALT_PHV}"]) {
                load 'jenkins/tests.groovy';
            }
        }
    }
}

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
        booleanParam( name: 'ALT_PHV',                    defaultValue: (boolean)(env.JOB_NAME =~ /alt-phv/),                                                                       description: "Internal: use ALT PHV pass"),
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

def runInDocker(Map namedArgs, String cmd) {
    // Supported named arguments and their default values:
    def args = [
        extraArgs: '',
        workingDir: '/bfn/bf-p4c-compilers/build',
        ctestParallelLevel: 1,
        maxCpu: null,
    ]

    assert args.keySet().containsAll(namedArgs.keySet())
    args.putAll(namedArgs)
    cmd = cmd.trim()

    if (args.maxCpu) {
        args.extraArgs += " --cpus=${args.maxCpu}"
    }

    sh """
        docker run --rm \
            --init \
            -w ${args.workingDir} \
            -e CTEST_PARALLEL_LEVEL=${args.ctestParallelLevel} \
            -e CTEST_OUTPUT_ON_FAILURE='true' \
            -e P4C_DO_RUN_LOAD_MEASUREMENT='yes' \
            -e UBSAN_OPTIONS=${params.UBSAN_OPTIONS} \
            -e ASAN_OPTIONS=${params.ASAN_OPTIONS} \
            ${args.extraArgs} \
            ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag} \
            ${cmd}
    """
}

def getBoostrapOpts() {
    if (params.ALT_PHV)
        return "-e BOOTSTRAP_EXTRA_OPTS=-DENABLE_ALT_PHV_ALLOC=ON"
    return ""
}

def sanitizersEnabled() {
    return params.UBSAN || params.ASAN
}

def runInDocker(String cmd) {
    runInDocker([:], cmd)
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
                kind = sanitizersEnabled() ? "sanitizers_" : params.ALT_PHV ? "altphv_" : ""
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
                            extra_opts = getBoostrapOpts()
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
                                        ${extra_opts} \
                                        -e MAKEFLAGS=j20 \
                                    "
                            """
                        },

                        'Non-unified': {
                            echo 'Testing non-unified build'
                            extra_opts = getBoostrapOpts()
                            sh """
                                make -Cdocker test-build \
                                    BUILD_ARGS="-e UNIFIED_BUILD=false ${extra_opts} -e MAKEFLAGS=j16"
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

            stage ('Test') {
                parallel (

                    'Short-running jobs': {

                        stage("Check code style") {
                            // This catchError makes sure the following jobs run even if this one
                            // fails, but the pipieline overall will fail. We explicitly don't catch
                            // interrupts (to preserve normal behaviour of job cancellation) and we
                            // need to explicitly fail the stage, otherwise only the step fails,
                            // which is not sufficiently visible in the UI.
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Checking code style'
                                runInDocker(
                                    maxCpu: 1,
                                    "make cpplint"
                                )
                            }
                        }

                        stage("Gtest") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                runInDocker(
                                    "ctest -R gtest"
                                )
                            }
                        }

                        stage("Documentation") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Testing Doxygen documentation build'
                                runInDocker(
                                    maxCpu: 1,
                                    'make doc'
                                )
                            }
                        }

                        stage("Check submodule refpoints") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                dir('checkRefpoints') {
                                    checkout scm
                                    sh 'git submodule update --init --recursive'
                                    sh 'scripts/check-git-submodules --skip-fetch'
                                }
                            }
                        }

                        stage("p414 basic IPv4 smoketests") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Running basic_ipv4 tests'
                                runInDocker(
                                    extraArgs: '--privileged',
                                    "ctest -R 'smoketest_programs_basic_ipv4'"
                                )
                            }
                        }

                        stage("p4o") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Running p4 obfuscator tests'
                                def bf_p4c_cid = sh (
                                    script: """
                                        docker run \
                                            --privileged \
                                            --rm -t -d \
                                            -w /bfn/bf-p4c-compilers/build/p4c \
                                            --entrypoint bash \
                                            ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag}
                                    """,
                                    returnStdout: true
                                ).trim()
                                echo "bf_p4c_cid: ${bf_p4c_cid}"

                                sh "docker pull ${DOCKER_PROJECT}/p4v:latest"
                                sh """
                                    mkdir -p p4o_regression
                                    docker cp ${bf_p4c_cid}:/bfn/bf-p4c-compilers/build p4o_regression/
                                    docker tag ${DOCKER_PROJECT}/p4v:latest ${DOCKER_PROJECT}/p4v:p4o_regression
                                """

                                try {
                                    def p4o_pwd = pwd()
                                    def p4v_cid = sh (
                                        script: """
                                            docker run \
                                                --privileged \
                                                --rm -t -d \
                                                -v ${p4o_pwd}/p4o_regression/build:/bfn/bf-p4c-compilers/build \
                                                -w /bfn/p4v/mutine/obfuscator/bin/scripts \
                                                --entrypoint bash \
                                                ${DOCKER_PROJECT}/p4v:p4o_regression
                                        """,
                                        returnStdout: true
                                    ).trim()
                                    echo "p4v_cid: ${p4v_cid}"

                                    sh """
                                        docker exec ${p4v_cid} \
                                            python3 -u main.py -t compiler -r serial -f tests.csv
                                    """

                                    sh """
                                        docker container stop ${bf_p4c_cid}
                                        docker container stop ${p4v_cid}
                                    """
                                } catch (err) {
                                    sh "echo 'p4o regression has failed'"
                                }
                            }
                        }
                    },

                    // Ideally, keep this in sync with
                    // https://github.com/intel-restricted/networking.switching.barefoot.sandals/blob/master/jenkins/bf_sde_compilers_package.sh
                    'Packaging': {
                        if (sanitizersEnabled())
                            return

                        sh """
                            make -Cdocker test-build \
                                    BUILD_ARGS="
                                        --cpus=4 \
                                        -e MAKEFLAGS=j4 \
                                        -e UNIFIED_BUILD=true \
                                    " \
                                    BUILD_SCRIPT="scripts/package_p4c_for_tofino.sh --build-dir build --enable-cb"
                        """
                    },

                    'Running Extreme PTF tests': {
                        echo 'Running Extreme PTF tests'
                        runInDocker(
                            maxCpu: 2,
                            extraArgs: '--privileged -e PKTPY=False',
                            workingDir: '/bfn/bf-p4c-compilers/scripts/run_custom_tests',
                            './run_extreme_tests.sh'
                        )
                    },

                    'Switch, Arista, Metrics': {
                        stage("Switch compilation") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Running switch profiles compilation for master'
                                runInDocker(
                                    ctestParallelLevel: 4,
                                    '''
                                        ctest -R '^tofino/.*switch_' \
                                            -E 'smoketest|p4_14|glass' \
                                            -LE 'METRICS'
                                    '''
                                )
                            }
                        }

                        stage("Arista must-pass") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Running some Arista must-pass tests that are excluded in Travis jobs'
                                runInDocker(
                                    ctestParallelLevel: 4,
                                    "ctest -R '^tofino/.*arista*' -L 'CUST_MUST_PASS'"
                                )
                            }
                        }

                        if (sanitizersEnabled())
                            return

                        stage("Generate switch compile-only metrics") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Running switch-14 and switch-16 tests for METRICS'
                                sh "docker pull ${DOCKER_PROJECT}/compiler_metrics:stage"
                                sh "mkdir -p metrics_store"
                                def metrics_cid = sh (
                                    script: """
                                        docker run --rm -t -d \
                                            -w /bfn/compiler_metrics/database \
                                            --entrypoint bash \
                                            ${DOCKER_PROJECT}/compiler_metrics:stage
                                    """,
                                    returnStdout: true
                                ).trim()
                                echo "metrics cid: ${metrics_cid}"
                                sh """
                                    docker cp \
                                        ${metrics_cid}:/bfn/compiler_metrics/database/compiler_metrics.sqlite \
                                        metrics_store/
                                    docker tag \
                                        ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag} \
                                        ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag}_metrics
                                """

                                def curr_pwd = pwd()
                                def p4c_cid = sh (
                                    script: """
                                        docker run --privileged --rm -t -d \
                                            -v ${curr_pwd}/metrics_store:/mnt \
                                            -w /bfn/bf-p4c-compilers/scripts/gen_reference_outputs \
                                            --entrypoint bash \
                                            ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag}_metrics
                                    """,
                                    returnStdout: true
                                ).trim()
                                echo "p4c cid: ${p4c_cid}"

                                echo "Generating metrics"
                                sh """
                                    docker exec ${p4c_cid} \
                                        cp /mnt/compiler_metrics.sqlite \
                                        /bfn/bf-p4c-compilers/scripts/gen_reference_outputs/database/
                                    docker exec ${p4c_cid} \
                                        python3 -u gen_ref_outputs.py \
                                            --tests_csv profiles.csv \
                                            --out_dir /bfn/bf-p4c-compilers/scripts/gen_reference_outputs/metrics_outputs/ \
                                            --process_metrics \
                                            --commit_sha ${bf_p4c_compilers_rev}
                                """

                                sh """
                                    docker container stop ${metrics_cid}
                                    docker container stop ${p4c_cid}
                                """
                            }
                        }
                    },

                    'stful, meters, hash-driven, other customer tests': {
                        stage("stful, meters, hash_driven tests") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Running stful, meters and hash_driven tests'
                                // Disable stful test (DRV-4189)
                                runInDocker(
                                    extraArgs: '--privileged',
                                    "ctest -R 'smoketest_programs_meters|smoketest_programs_hash_driven'"
                                )
                            }
                        }

                        stage("Remaining customer tests") {
                            catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                echo 'Running remaining customer must passes that are excluded in Travis jobs'
                                runInDocker(
                                    ctestParallelLevel: 1,
                                    "ctest -R '^tofino/' -L 'CUST_MUST_PASS' -E 'arista'"
                                )
                            }
                        }
                    },

                    "switch_16 Tofino tests (part 1)": {
                        echo 'Running bf-switch bfrt tests for Tofino for X1 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino/.*smoketest_switch_16_Tests_x1'"
                        )
                    },

                    "switch_16 Tofino tests (part 2)": {
                        echo 'Running bf-switch bfrt tests for Tofino for X2 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino/.*smoketest_switch_16_Tests_x2'"
                        )
                    },

                    "switch 16 Tofino 2 tests (part 1)": {
                        echo 'Running bf-switch bfrt tests for Tofino2 for Y1 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino2/.*smoketest_switch_16_Tests_y1'"
                        )

                        echo 'Running bf-switch compile-only for Tofino2 not covered in PTF'
                        runInDocker '''
                            ctest -R '^tofino2/.*smoketest_switch_16_compile' -LE 'PR_REG_PTF'
                        '''
                    },

                    "switch_16 Tofino 2 tests (part 2) and basic_ipv4": {
                        echo 'Running bf-switch bfrt tests for Tofino2 for Y2 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino2/.*smoketest_switch_16_Tests_y2'"
                        )
                    },

                    "Tofino (part 1)": {
                        echo 'Running tofino part 1 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            '''
                                ctest \
                                    -R '^tofino/' \
                                    -E 'smoketest|tofino/switch_|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*' \
                                    -LE 'UNSTABLE|GTS_WEEKLY|NON_PR_TOFINO|p414_nightly|determinism' \
                                    -I 0,,3
                            '''
                        )
                    },

                    "Tofino (part 2)": {
                        echo 'Running tofino part 2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            '''
                                ctest \
                                    -R '^tofino/' \
                                    -E 'smoketest|tofino/switch_|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*' \
                                    -LE 'UNSTABLE|GTS_WEEKLY|NON_PR_TOFINO|p414_nightly|determinism' \
                                    -I 1,,3
                            '''
                        )
                    },

                    "Tofino (part 3)": {
                        echo 'Running tofino part 3 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            '''
                                ctest \
                                    -R '^tofino/' \
                                    -E 'smoketest|tofino/switch_|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*' \
                                    -LE 'UNSTABLE|GTS_WEEKLY|NON_PR_TOFINO|p414_nightly|determinism' \
                                    -I 2,,3
                            '''
                        )
                    },

                    "Tofino 2 (part 1)": {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            '''
                                ctest \
                                    -R '^tofino2' \
                                    -E 'ignore_test_|smoketest|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|npb-master-ptf|npb-folded-pipe|npb-multi-prog' \
                                    -LE 'UNSTABLE|determinism' \
                                    -I 0,,3
                            '''
                        )
                    },

                    "Tofino 2 (part 2)": {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            '''
                                ctest \
                                    -R '^tofino2' \
                                    -E 'ignore_test_|smoketest|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|npb-master-ptf|npb-folded-pipe|npb-multi-prog' \
                                    -LE 'UNSTABLE|determinism' \
                                    -I 1,,3
                            '''
                        )
                    },

                    "Tofino 2 (part 3)": {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            '''
                                ctest \
                                    -R '^tofino2' \
                                    -E 'ignore_test_|smoketest|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|npb-master-ptf|npb-folded-pipe|npb-multi-prog' \
                                    -LE 'UNSTABLE|determinism' \
                                    -I 2,,3
                            '''
                        )
                    },

                    "Tofino 3": {
                        echo 'Running tofino3 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            "ctest -R '^tofino3' -LE 'determinism'"
                        )
                    },

                    "Tofino 5": {
                        echo 'Running tofino5 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 1,
                            "ctest -R '^tofino5' -LE 'ptf|determinism'"
                        )
                    },

                    "Determinism test - All Tofino versions": {
                        echo 'Running determinism tests for all Tofino versions'
                        runInDocker(
                            ctestParallelLevel: 2,
                            "ctest -L 'determinism'"
                        )
                    },
                    "Installed p4c tests": {
                        echo 'Running driver tests on installed p4c'
                        runInDocker(
                            maxCpu: 1,
                            extraArgs: '--privileged',
                            workingDir: '/bfn/bf-p4c-compilers/scripts',
                            """
                                python3.8 \
                                    -u test_p4c_driver.py \
                                    -j 1 \
                                    --print-on-failure \
                                    --compiler '/usr/local/bin/p4c'
                            """
                        )
                    },

                    // Benchmarks
                    /*'Compile time benchmark' : {
                        build job: 'bf-p4c-compilers-performance-bench',
                        parameters: [
                            string(name: "BFP4C_DOCKER_IMAGE",
                                   value: "${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag}")
                        ]
                    }*/
                )
            }

        }
    }
}

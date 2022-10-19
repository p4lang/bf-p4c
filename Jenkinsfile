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
        booleanParam(name: 'ALT_PHV', defaultValue: (boolean)(env.JOB_NAME =~ /alt-phv/), description: "Internal: use ALT PHV pass")
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
    ]

    assert args.keySet().containsAll(namedArgs.keySet())
    args.putAll(namedArgs)
    cmd = cmd.trim()

    sh """
        docker run --rm \
            --init \
            -w ${args.workingDir} \
            -e CTEST_PARALLEL_LEVEL=${args.ctestParallelLevel} \
            -e CTEST_OUTPUT_ON_FAILURE='true' \
            -e P4C_DO_RUN_LOAD_MEASUREMENT='yes' \
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

def runInDocker(String cmd) {
    runInDocker([:], cmd)
}

node ('compiler-travis') {
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
                kind = params.ALT_PHV ? "altphv_" : ""
                image_tag_branch = "${kind}${env.BRANCH_NAME.toLowerCase()}"
                image_tag = "${image_tag_branch}_${bf_p4c_compilers_rev}".replace('/', '--')
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
                    mkdir -p ~/.ccache_bf-p4c-compilers
                    docker build \
                        --pull \
                        --cache-from ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag_branch} \
                        -f docker/Dockerfile.tofino \
                        -t bf-p4c-compilers_intermediate_${image_tag} \
                        --build-arg DOCKER_PROJECT=${DOCKER_PROJECT} \
                        --build-arg MAKEFLAGS=j16 \
                        --target=environment \
                        .
                """
            }

            if (image_pulled != 'true') {
                stage ('Build final') {
                    parallel (
                        'Unified': {
                            echo 'Building final Docker image to run tests with (unified build)'
                            extra_opts = getBoostrapOpts()
                            sh """
                                docker rm -f bf-p4c-compilers_build_${image_tag} \
                                    || true
                                docker run \
                                    --name bf-p4c-compilers_build_${image_tag} \
                                    -v ~/.ccache_bf-p4c-compilers:/root/.ccache \
                                    -e UNIFIED_BUILD=true \
                                    -e MAKEFLAGS=j16 \
                                    ${extra_opts} \
                                    bf-p4c-compilers_intermediate_${image_tag} \
                                    /bfn/bf-p4c-compilers/docker/docker_build.sh
                                docker commit \
                                    --change 'CMD ["/bin/bash"]' \
                                    bf-p4c-compilers_build_${image_tag} \
                                    ${DOCKER_PROJECT}/bf-p4c-compilers:${image_tag}
                                docker rm -f bf-p4c-compilers_build_${image_tag}
                            """
                        },

                        'Non-unified': {
                            echo 'Testing non-unified build'
                            extra_opts = getBoostrapOpts()
                            sh """
                                docker run --rm \
                                    -v ~/.ccache_bf-p4c-compilers:/root/.ccache \
                                    -e UNIFIED_BUILD=false \
                                    -e MAKEFLAGS=j16 \
                                    ${extra_opts} \
                                    bf-p4c-compilers_intermediate_${image_tag} \
                                    /bfn/bf-p4c-compilers/docker/docker_build.sh
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
                                    to: "vojtech.havel@intel.com,prathima.kotikalapudi@intel.com",
                                    attachLog: true
                    }
                }
            }

            stage ('Test') {
                parallel (

                    'Running Extreme PTF tests': {
                        echo 'Running Extreme PTF tests'
                        runInDocker(
                            extraArgs: '--privileged -e PKTPY=False',
                            workingDir: '/bfn/bf-p4c-compilers/scripts/run_custom_tests',
                            './run_extreme_tests.sh'
                        )
                    },

                    'Generate switch compile-only metrics': {
                        echo 'Running switch profiles compilation for master'
                        runInDocker(
                            ctestParallelLevel: 4,
                            '''
                                ctest -R '^tofino/.*switch_' \
                                    -E 'smoketest|p4_14|glass' \
                                    -LE 'METRICS'
                            '''
                        )

                        echo 'Running some Arista must-pass tests that are excluded in Travis jobs'
                        runInDocker(
                            ctestParallelLevel: 8,
                            "ctest -R '^tofino/.*arista*' -L 'CUST_MUST_PASS'"
                        )

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
                    },

                    'stful, meters, hash-driven, other customer tests': {
                        echo 'Running stful, meters and hash_driven tests'
                        // Disable stful test (DRV-4189)
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R 'smoketest_programs_meters|smoketest_programs_hash_driven'"
                        )

                        echo 'Running remaining customer must passes that are excluded in Travis jobs'
                        runInDocker(
                            ctestParallelLevel: 1,
                            "ctest -R '^tofino/' -L 'CUST_MUST_PASS' -E 'arista'"
                        )
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

                        echo 'Running basic_ipv4 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R 'smoketest_programs_basic_ipv4'"
                        )
                    },

                    "Travis - Tofino (part 1)": {
                        echo 'Running tofino part 1 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 8,
                            '''
                                ctest \
                                    -R '^tofino/' \
                                    -E 'smoketest|/programs|/internal_p4_14|p4testgen|tofino/switch_|c2_COMPILER|c2/COMPILER|p4_16_programs|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|ptf/digest.p4|digest-std-p4runtime' \
                                    -LE 'UNSTABLE|GTS_WEEKLY|NON_PR_TOFINO|p414_nightly|determinism'
                            '''
                        )
                    },

                    "Travis - Tofino (part 2)": {
                        echo 'Running tofino part 2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 1,
                            '''
                                ctest \
                                    -R '^tofino/(.*programs|.*internal_p4_14)' \
                                    -E 'TestRealData|_basic_ipv4|_stful|_meters|_hash_driven|_dkm|_exm_smoke_test|_exm_direct_|_exm_direct_1_|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|perf_test_alpm|entry_read_from_hw' \
                                    -LE 'UNSTABLE|p414_nightly|determinism'
                            '''
                        )
                    },

                    "Travis - Tofino 2 (part 1)": {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 8,
                            '''
                                ctest \
                                    -R '^tofino2|gtest' \
                                    -L 'JENKINS_PART1|gtest' \
                                    -E 'ignore_test_|smoketest|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|/dkm/|entry_read_from_hw|/p4_14/stf/decaf_9.*|ptf/digest.p4|npb-master-ptf' \
                                    -LE 'UNSTABLE|determinism'
                            '''
                        )
                    },

                    "Travis - Tofino 2 (part 2)": {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 1,
                            '''
                                ctest \
                                    -R '^tofino2' \
                                    -L 'JENKINS_PART2' \
                                    -E 'ignore_test_|smoketest|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|/dkm/|entry_read_from_hw|/p4_14/stf/decaf_9.*|ptf/digest.p4|3174' \
                                    -LE 'UNSTABLE|determinism'
                            '''
                        )
                    },

                    "Travis - Tofino 3": {
                        echo 'Running tofino3 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 2,
                            "ctest -R '^tofino3' -LE 'determinism'"
                        )
                    },

                    "Travis - Tofino 5": {
                        echo 'Running tofino5 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 2,
                            "ctest -R '^tofino5' -LE 'ptf|determinism'"
                        )
                    },

                    "Determinism test - All Tofino versions": {
                        echo 'Running determinism tests for all Tofino versions'
                        runInDocker(
                            "ctest -L 'determinism'"
                        )
                    },

                    "p4o": {
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
                    },

                    "Installed p4c tests": {
                        echo 'Running driver tests on installed p4c'
                        runInDocker(
                            extraArgs: '--privileged',
                            workingDir: '/bfn/bf-p4c-compilers/scripts',
                            """
                                python3.8 \
                                    -u test_p4c_driver.py \
                                    -j 4 \
                                    --print-on-failure \
                                    --compiler '/usr/local/bin/p4c'
                            """
                        )
                    },

                    "Documentation": {
                        echo 'Testing Doxygen documentation build'
                        runInDocker(
                            'make doc'
                        )
                    },

                    "Check code style": {
                        echo 'Checking code style'
                        runInDocker(
                            '''
                                /bin/bash -c "\
                                    ln -s /usr/bin/python3 /usr/bin/python; \
                                    ctest -R 'cpplint' \
                                "
                            '''
                        )
                    },

                    "Check submodule refpoints": {
                        dir('checkRefpoints') {
                            checkout scm
                            sh 'git submodule update --init --recursive'
                            sh 'scripts/check-git-submodules --skip-fetch'
                        }
                    },

                    // Ideally, keep this in sync with
                    // https://github.com/intel-restricted/networking.switching.barefoot.sandals/blob/master/jenkins/bf_sde_compilers_package.sh
                    'Packaging' : {
                        sh """
                            mkdir -p ~/.ccache_bf-p4c-compilers
                            docker run \
                                -v ~/.ccache_bf-p4c-compilers:/root/.ccache \
                                -e MAKEFLAGS=j2 \
                                -e UNIFIED_BUILD=true \
                                bf-p4c-compilers_intermediate_${image_tag} \
                                scripts/package_p4c_for_tofino.sh --build-dir build --enable-cb
                        """
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

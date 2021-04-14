/**
 * Libraries contain reusabile snippets that can be reused across multiple projects.
 */
@Library('bf-jenkins-utils@master')_

node {
    // kill any previous runs of the same PR that may be in progress
    stopPreviousRuns(this)
}

node ('compiler-nodes') {
    // Clean workspace before doing anything
    sh "sudo chmod -R 777 ."
    deleteDir()
    environment {
        def bf_p4c_compilers_rev = ""
        def bf_p4c_compilers_rev_short = ""
        def image_pulled = ""
        def bf_switch_rev = ""
        def metrics_cid = ""
        def p4c_cid = ""
    }
    try {
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

                stage ('Pull image') {
                    echo 'Attempting to pull existing bf-p4c-compilers Docker image'

                    withCredentials([usernamePassword(
                        credentialsId: "bfndocker",
                        usernameVariable: "DOCKER_USERNAME",
                        passwordVariable: "DOCKER_PASSWORD"
                    )]) {
                        sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    }

                    try {
                        sh "docker pull barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev}"
                        image_pulled = 'true'
                        echo "Pulled image bf-p4c-compilers:${bf_p4c_compilers_rev}"
                    } catch (err) {
                        image_pulled = 'false'
                        echo 'Nothing pulled'
                    }
                }

                if (image_pulled != 'true') {

                    stage ('Setup build') {
                        echo 'Checking out p4factory for reference'
                        sh 'git clone git@github.com:barefootnetworks/p4factory.git'
                        dir('p4factory') {
                            p4factory_rev = sh (
                                script: 'git rev-parse HEAD',
                                returnStdout: true
                            ).trim()
                            echo "Using p4factory:${p4factory_rev}"
                            sh 'git log -1 --stat'

                            // Extract revision of bf-switch submodule used in p4factory
                            // ! The submodule is not initialized at this point
                            bf_switch_rev = sh (
                                script: "git ls-files -s submodules/bf-switch | cut -d' ' -f2",
                                returnStdout: true
                            ).trim()
                        }
                        sh 'rm -rf p4factory'

                        echo "Initializing bf-p4c-compilers submodules"
                        sh "git submodule update --init --recursive"

                        echo "Updating switch_16 submodule to bf-switch:${bf_switch_rev}"
                        dir('p4-tests/p4_16/switch_16') {
                            sh """
                                git fetch origin ${bf_switch_rev} &&
                                git checkout ${bf_switch_rev} &&
                                git submodule update --init --recursive &&
                                git log -1 --stat
                            """
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

                        echo 'Building intermediate Docker image'
                        sh """
                            mkdir -p ~/.ccache_bf-p4c-compilers &&
                            docker build \
                                --pull \
                                -f docker/Dockerfile.tofino \
                                -t bf-p4c-compilers_intermediate_${bf_p4c_compilers_rev} \
                                --build-arg MAKEFLAGS=j16 \
                                --build-arg BUILD_FOR=jenkins-intermediate \
                                --build-arg BFN_P4C_GIT_SHA=${bf_p4c_compilers_rev_short} \
                                .
                        """
                    }

                    stage ('Build final') {
                        parallel (

                            'Unified': {
                                echo 'Building final Docker image to run tests with (unified build)'
                                sh """
                                    docker run \
                                        --name bf-p4c-compilers_build_${bf_p4c_compilers_rev} \
                                        -v ~/.ccache_bf-p4c-compilers:/root/.ccache \
                                        -e MAKEFLAGS=j16 \
                                        -e BUILD_FOR=jenkins-final \
                                        -e IMAGE_TYPE=test \
                                        -e BUILD_GLASS=false \
                                        -e GEN_REF_OUTPUTS=false \
                                        -e TOFINO_P414_TEST_ARCH_TNA=false \
                                        bf-p4c-compilers_intermediate_${bf_p4c_compilers_rev} \
                                        /bfn/bf-p4c-compilers/docker/docker_build.sh &&
                                    docker commit \
                                        bf-p4c-compilers_build_${bf_p4c_compilers_rev} \
                                        barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev} &&
                                    docker rm bf-p4c-compilers_build_${bf_p4c_compilers_rev}
                                """
                            },

                            'Non-unified': {
                                echo 'Testing non-unified build'
                                sh """
                                    docker run --rm \
                                        -v ~/.ccache_bf-p4c-compilers:/root/.ccache \
                                        -e MAKEFLAGS=j16 \
                                        -e BUILD_FOR=jenkins-final \
                                        -e IMAGE_TYPE=non-unified \
                                        -e BUILD_GLASS=false \
                                        -e GEN_REF_OUTPUTS=false \
                                        -e TOFINO_P414_TEST_ARCH_TNA=false \
                                        bf-p4c-compilers_intermediate_${bf_p4c_compilers_rev} \
                                        /bfn/bf-p4c-compilers/docker/docker_build.sh
                                """
                            },

                        )
                    }

                    stage ('Push image') {
                        echo "Pushing the built Docker image bf-p4c-compilers:${bf_p4c_compilers_rev}"
                        sh "docker push barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev}"
                    }

                }

            }
        }
    } catch (err) {
        currentBuild.result = 'FAILED'
        throw err
    }
}

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
            -w ${args.workingDir} \
            -e CTEST_PARALLEL_LEVEL=${args.ctestParallelLevel} \
            -e CTEST_OUTPUT_ON_FAILURE='true' \
            ${args.extraArgs} \
            barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev} \
            ${cmd}
    """
}

def runInDocker(String cmd) {
    runInDocker([:], cmd)
}

node ('compiler-travis') {
    // Clean workspace before doing anything
    sh "sudo chmod -R 777 ."
    deleteDir()
    echo 'Pulling the built Docker image for the PR'
    withCredentials([usernamePassword(
        credentialsId: "bfndocker",
        usernameVariable: "DOCKER_USERNAME",
        passwordVariable: "DOCKER_PASSWORD"
    )]) {
        sh """
            docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
            docker pull barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev}
            docker pull barefootnetworks/p4v:latest
        """
    }
    ansiColor('xterm') {
        timestamps {

            stage ('Test') {
                parallel (

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
                            ctestParallelLevel: 4,
                            "ctest -R '^tofino/.*arista*' -L 'CUST_MUST_PASS'"
                        )

                        echo 'Running Extreme PTF tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            workingDir: '/bfn/bf-p4c-compilers/scripts/run_custom_tests',
                            './run_extreme_tests.sh'
                        )

                        echo 'Running switch-14 and switch-16 tests for METRICS'
                        sh "docker pull barefootnetworks/compiler_metrics:stage"
                        sh "mkdir -p metrics_store"
                        metrics_cid = sh (
                            script: '''
                                docker run --rm -t -d \
                                    -w /bfn/compiler_metrics/database \
                                    --entrypoint bash \
                                    barefootnetworks/compiler_metrics:stage
                            ''',
                            returnStdout: true
                        ).trim()
                        echo "metrics cid: ${metrics_cid}"
                        sh """
                            docker cp \
                                ${metrics_cid}:/bfn/compiler_metrics/database/compiler_metrics.sqlite \
                                metrics_store/
                            docker tag \
                                barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev} \
                                barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev}_metrics
                        """

                        def curr_pwd = pwd()
                        p4c_cid = sh (
                            script: """
                                docker run --privileged --rm -t -d \
                                    -v ${curr_pwd}/metrics_store:/mnt \
                                    -w /bfn/bf-p4c-compilers/scripts/gen_reference_outputs \
                                    --entrypoint bash \
                                    barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev}_metrics
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
                                python -u gen_ref_outputs.py \
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

                    'Switch MSDC and DC_BASIC, stful, meters, hash-driven, other customer tests': {
                        echo 'Running switch PD tests for MSDC_PROFILE_BRIG'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino/.*smoketest_switch_msdc' -LE 'UNSTABLE'"
                        )

                        echo 'Running switch PD tests for DC_BASIC_PROFILE_BRIG'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino/.*smoketest_switch_dc_basic' -LE 'UNSTABLE'"
                        )

                        echo 'Running stful, meters and hash_driven tests'
                        // Disable stful test (DRV-4189)
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R 'smoketest_programs_meters|smoketest_programs_hash_driven'"
                        )

                        echo 'Running remaining customer must passes that are excluded in Travis jobs'
                        runInDocker(
                            ctestParallelLevel: 4,
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
                            ctestParallelLevel: 4,
                            '''
                                ctest \
                                    -R '^tofino/' \
                                    -E 'smoketest|/programs|/internal_p4_14|p4testgen|tofino/switch_|c2_COMPILER|c2/COMPILER|p4_16_programs|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|ptf/digest.p4|digest-std-p4runtime' \
                                    -LE 'GTS_WEEKLY|NON_PR_TOFINO|p414_nightly'
                            '''
                        )
                    },

                    "Travis - Tofino (part 2)": {
                        echo 'Running tofino part 2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 4,
                            '''
                                ctest \
                                    -R '^tofino/(.*programs|.*internal_p4_14)' \
                                    -E 'TestRealData|_basic_ipv4|_stful|_meters|_hash_driven|_dkm|_exm_smoke_test|_exm_direct_|_exm_direct_1_|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|perf_test_alpm|entry_read_from_hw' \
                                    -LE 'p414_nightly'
                            '''
                        )
                    },

                    "Travis - Tofino 2 (part 1)": {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 4,
                            '''
                                ctest \
                                    -R '^tofino2|cpplint|gtest' \
                                    -L 'JENKINS_PART1|cpplint|gtest' \
                                    -E 'ignore_test_|smoketest|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|/dkm/|entry_read_from_hw|/p4_14/stf/decaf_9.*|ptf/digest.p4|npb-master-ptf'
                            '''
                        )
                    },

                    "Travis - Tofino 2 (part 2)": {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 4,
                            '''
                                ctest \
                                    -R '^tofino2' \
                                    -L 'JENKINS_PART2' \
                                    -E 'ignore_test_|smoketest|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|/dkm/|entry_read_from_hw|/p4_14/stf/decaf_9.*|ptf/digest.p4|3174'
                            '''
                        )
                    },

                    "Travis - Tofino 3": {
                        echo 'Running tofino3 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 4,
                            "ctest -R '^tofino3' -LE 'ptf'"
                        )
                    },

                    "p4o": {
                        echo 'Running p4 obfuscator tests'
                        def bf_p4c_cid = ""
                        bf_p4c_cid = sh (
                            script: """
                                docker run \
                                    --privileged \
                                    --rm -t -d \
                                    -w /bfn/bf-p4c-compilers/build/p4c \
                                    --entrypoint bash \
                                    barefootnetworks/bf-p4c-compilers:${bf_p4c_compilers_rev}
                            """,
                            returnStdout: true
                        ).trim()
                        echo "bf_p4c_cid: ${bf_p4c_cid}"

                        sh """
                            mkdir -p p4o_regression
                            docker cp ${bf_p4c_cid}:/bfn/bf-p4c-compilers/build p4o_regression/
                            docker tag barefootnetworks/p4v:latest barefootnetworks/p4v:p4o_regression
                        """

                        try {
                            def p4o_pwd = pwd()
                            def p4v_cid = ""
                            p4v_cid = sh (
                                script: """
                                    docker run \
                                        --privileged \
                                        --rm -t -d \
                                        -v ${p4o_pwd}/p4o_regression/build:/bfn/bf-p4c-compilers/build \
                                        -w /bfn/p4v/mutine/obfuscator/bin/scripts \
                                        --entrypoint bash \
                                        barefootnetworks/p4v:p4o_regression
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
                                python3 \
                                    -u test_p4c_driver.py \
                                    -j 4 \
                                    --print-on-failure \
                                    --compiler '/usr/local/bin/p4c'
                            """
                        )
                    },

                    "Check submodule refpoints": {
                        dir('checkRefpoints') {
                            checkout scm
                            sh 'git submodule update --init --recursive'
                            sh 'scripts/check-git-submodules --skip-fetch'
                        }
                    },

                    "Check copyright messages": {
                        runInDocker(
                            workingDir: '/bfn/bf-p4c-compilers',
                            'scripts/packaging/copyright-stamp /bfn/bf-p4c-compilers'
                        )
                    },

                )
            }

        }
    }
}

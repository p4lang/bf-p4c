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
            ${DOCKER_PROJECT}/bf-p4c-compilers:${IMAGE_TAG} \
            ${cmd}
    """
}

def runInDocker(String cmd) {
    runInDocker([:], cmd)
}

// GTS and p414_nightly only exists for Tofino 1
CTEST_LABEL_EXCLUDE_ALL = 'UNSTABLE|GTS_WEEKLY|NON_PR_TOFINO|METRICS|p414_nightly|determinism'
CTEST_LABEL_EXCLUDE_T5 = "${CTEST_LABEL_EXCLUDE_ALL}|ptf"

CTEST_PATH_EXCLUDE_T1 = 'smoketest_switch_'
CTEST_PATH_EXCLUDE_T2 = 'ignore_test_|smoketest_switch_|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|npb-master-ptf|npb-folded-pipe|npb-multi-prog'

// this Jenkins file is not intended to be executed directly, instead it shold
// be loaded by a top-level scripted pipeline
pipeline {
    // allows file loading
    agent none

    stages {
        stage("Tests") {
            parallel {
                stage('Short-running jobs') {
                    stages {
                        stage("Check code style") {
                            steps {
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
                        }

                        stage("Gtest") {
                            steps {
                                catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                    runInDocker(
                                        "ctest -R gtest"
                                    )
                                }
                            }
                        }

                        stage("Documentation") {
                            steps {
                                catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                    echo 'Testing Doxygen documentation build'
                                    runInDocker(
                                        maxCpu: 1,
                                        'make doc'
                                    )
                                }
                            }
                        }

                        stage("Check submodule refpoints") {
                            steps {
                                catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                    sh 'scripts/check-git-submodules --skip-fetch'
                                }
                            }
                        }

                        stage("Installed p4c tests") {
                            steps {
                                catchError(catchInterruptions: false, stageResult: 'FAILURE') {
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
                                }
                            }
                        }

                        stage("p4o") {
                            steps {
                                catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                                    script {
                                        echo 'Running p4 obfuscator tests'
                                        def bf_p4c_cid = sh (
                                            script: """
                                                docker run \
                                                    --privileged \
                                                    --rm -t -d \
                                                    -w /bfn/bf-p4c-compilers/build/p4c \
                                                    --entrypoint bash \
                                                    ${DOCKER_PROJECT}/bf-p4c-compilers:${IMAGE_TAG}
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
                            }
                        }
                    }
                }

                // Ideally, keep this in sync with
                // https://github.com/intel-restricted/networking.switching.barefoot.sandals/blob/master/jenkins/bf_sde_compilers_package.sh
                stage('Packaging') {
                    when { expression { SANITIZERS_ENABLED != "true" } }
                    steps {

                        sh """
                            make -Cdocker test-build \
                                    BUILD_ARGS="
                                        --cpus=4 \
                                        -e MAKEFLAGS=j4 \
                                        -e UNIFIED_BUILD=true \
                                    " \
                                    BUILD_SCRIPT="scripts/package_p4c_for_tofino.sh --build-dir build --enable-cb"
                        """
                    }
                }

                stage('Running Extreme PTF tests') {
                    steps {
                        echo 'Running Extreme PTF tests'
                        runInDocker(
                            maxCpu: 2,
                            extraArgs: '--privileged -e PKTPY=False',
                            workingDir: '/bfn/bf-p4c-compilers/scripts/run_custom_tests',
                            './run_extreme_tests.sh'
                        )
                    }
                }


                stage("Generate switch compile-only metrics") {
                    when { expression { SANITIZERS_ENABLED != "true" } }
                    steps {
                        catchError(catchInterruptions: false, stageResult: 'FAILURE') {
                            script {
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
                                        ${DOCKER_PROJECT}/bf-p4c-compilers:${IMAGE_TAG} \
                                        ${DOCKER_PROJECT}/bf-p4c-compilers:${IMAGE_TAG}_metrics
                                """

                                def curr_pwd = pwd()
                                def p4c_cid = sh (
                                    script: """
                                        docker run --privileged --rm -t -d \
                                            -v ${curr_pwd}/metrics_store:/mnt \
                                            -w /bfn/bf-p4c-compilers/scripts/gen_reference_outputs \
                                            --entrypoint bash \
                                            ${DOCKER_PROJECT}/bf-p4c-compilers:${IMAGE_TAG}_metrics
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
                                            --commit_sha ${BF_P4C_REV}
                                """

                                sh """
                                    docker container stop ${metrics_cid}
                                    docker container stop ${p4c_cid}
                                """
                            }
                        }
                    }
                }

                stage("switch_16 Tofino tests (part 1)") {
                    steps {
                        echo 'Running bf-switch bfrt tests for Tofino for X1 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino/.*smoketest_switch_16_Tests_x1'"
                        )
                    }
                }


                stage("switch_16 Tofino tests (part 2)") {
                    steps {
                        echo 'Running bf-switch bfrt tests for Tofino for X2 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino/.*smoketest_switch_16_Tests_x2'"
                        )
                    }
                }

                stage("switch 16 Tofino 2 tests (part 1)") {
                    steps {
                        echo 'Running bf-switch bfrt tests for Tofino2 for Y1 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino2/.*smoketest_switch_16_Tests_y1'"
                        )

                        echo 'Running bf-switch compile-only for Tofino2 not covered in PTF'
                        runInDocker '''
                            ctest -R '^tofino2/.*smoketest_switch_16_compile' -LE 'PR_REG_PTF'
                        '''
                    }
                }

                stage("switch_16 Tofino 2 tests (part 2) and basic_ipv4") {
                    steps {
                        echo 'Running bf-switch bfrt tests for Tofino2 for Y2 Profile'
                        runInDocker(
                            extraArgs: '--privileged',
                            "ctest -R '^tofino2/.*smoketest_switch_16_Tests_y2'"
                        )
                    }
                }

                stage("Tofino (part 1)") {
                    steps {
                        echo 'Running tofino part 1 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            """
                                ctest \
                                    -R '^tofino/' \
                                    -E '${CTEST_PATH_EXCLUDE_T1}' \
                                    -LE '${CTEST_LABEL_EXCLUDE_ALL}' \
                                    -I 0,,3
                            """
                        )
                    }
                }

                stage("Tofino (part 2)") {
                    steps {
                        echo 'Running tofino part 2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            """
                                ctest \
                                    -R '^tofino/' \
                                    -E '${CTEST_PATH_EXCLUDE_T1}' \
                                    -LE '${CTEST_LABEL_EXCLUDE_ALL}' \
                                    -I 1,,3
                            """
                        )
                    }
                }

                stage("Tofino (part 3)") {
                    steps {
                        echo 'Running tofino part 3 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            """
                                ctest \
                                    -R '^tofino/' \
                                    -E '${CTEST_PATH_EXCLUDE_T1}' \
                                    -LE '${CTEST_LABEL_EXCLUDE_ALL}' \
                                    -I 2,,3
                            """
                        )
                    }
                }

                stage("Tofino 2 (part 1)") {
                    steps {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            """
                                ctest \
                                    -R '^tofino2' \
                                    -E '${CTEST_PATH_EXCLUDE_T2}' \
                                    -LE '${CTEST_LABEL_EXCLUDE_ALL}' \
                                    -I 0,,3
                            """
                        )
                    }
                }

                stage("Tofino 2 (part 2)") {
                    steps {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            """
                                ctest \
                                    -R '^tofino2' \
                                    -E '${CTEST_PATH_EXCLUDE_T2}' \
                                    -LE '${CTEST_LABEL_EXCLUDE_ALL}' \
                                    -I 1,,3
                            """
                        )
                    }
                }

                stage("Tofino 2 (part 3)") {
                    steps {
                        echo 'Running tofino2 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            """
                                ctest \
                                    -R '^tofino2' \
                                    -E '${CTEST_PATH_EXCLUDE_T2}' \
                                    -LE '${CTEST_LABEL_EXCLUDE_ALL}' \
                                    -I 2,,3
                            """
                        )
                    }
                }

                stage("Tofino 3") {
                    steps {
                        echo 'Running tofino3 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 3,
                            "ctest -R '^tofino3' -LE '${CTEST_LABEL_EXCLUDE_ALL}'"
                        )
                    }
                }

                stage("Tofino 5") {
                    steps {
                        echo 'Running tofino5 tests'
                        runInDocker(
                            extraArgs: '--privileged',
                            ctestParallelLevel: 1,
                            "ctest -R '^tofino5' -LE '${CTEST_LABEL_EXCLUDE_T5}'"
                        )
                    }
                }

                stage("Determinism test - All Tofino versions") {
                    steps {
                        echo 'Running determinism tests for all Tofino versions'
                        runInDocker(
                            ctestParallelLevel: 2,
                            "ctest -L 'determinism'"
                        )
                    }
                }
            }
        }
    }
}

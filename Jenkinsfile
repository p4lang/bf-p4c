/**
 * Libraries contain reusabile snippets that can be reused across multiple projects.
 */
@Library('bf-jenkins-utils@master')_

node {
    // kill any previous runs of the same PR that may be in progress
    stopPreviousRuns(this)
}

node ('compiler-nodes') {
    sh "echo 'Building docker image for PR'"
    // Clean workspace before doing anything
    sh "sudo chmod -R 777 ."
    deleteDir()
    environment {
        def image_tag = ""
        def git_sha = ""
        def metrics_cid = ""
        def p4c_cid = ""
        def switch_16_branch = ""
    }
    try {
        stage ('Setup') {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Checking out p4factory build'"
                    sh "git clone git@github.com:barefootnetworks/p4factory.git"
                    dir('p4factory') {
                        sh "echo 'p4factory current commit:'"
                        sh "git log -1 --stat"
                        switch_16_branch = sh (
                            script: "git ls-files -s submodules/bf-switch | cut -d' ' -f2",
                            returnStdout: true
                        ).trim()
                        sh "echo 'bf-switch last working p4factory commit: ' $switch_16_branch"
                    }
                }
            }
        }
        stage ('Checkout') {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Checking out bf-p4c-compilers build'"
                    checkout scm
                    image_tag = sh (
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    sh "echo 'image tag: ' $image_tag"
                    git_sha = sh (
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    sh "echo 'bf-p4c-compilers git sha: ' $git_sha"
                }
            }
        }
        stage ('Build') {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Building bf-p4c-compilers in docker'"
                    withCredentials([usernamePassword(
                        credentialsId: "bfndocker",
                        usernameVariable: "DOCKER_USERNAME",
                        passwordVariable: "DOCKER_PASSWORD"
                    )]) {
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                        try {
                            // Try to see if the docker image is available from previous run
                            sh "docker pull barefootnetworks/bf-p4c-compilers:${image_tag}"
                        } catch (err) {
                            // If image not available, build
                            sh "git submodule update --init --recursive"
                            // Update switch.p4-16 to the latest known working refpoint
                            switch_16_repo = 'p4-tests/p4_16/switch_16'
                            sh "git -C $switch_16_repo fetch origin $switch_16_branch && git -C $switch_16_repo checkout $switch_16_branch"
                            sh "echo 'Using switch_16: ' && git -C p4-tests/p4_16/switch_16 log HEAD^..HEAD"
                            sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                            sh "docker pull barefootnetworks/model:tofino_debug"
                            sh "docker build -f docker/Dockerfile.tofino -t bf-p4c-compilers_${image_tag} --build-arg MAKEFLAGS=j16 --build-arg BFN_P4C_GIT_SHA=${git_sha} ."
                            sh "echo 'Tag and push docker image'"
                            sh "docker tag bf-p4c-compilers_${image_tag} barefootnetworks/bf-p4c-compilers:${image_tag}"
                            sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                            sh "docker push barefootnetworks/bf-p4c-compilers:${image_tag}"
                        }
                    }
                }
            }
        }
    } catch (err) {
        currentBuild.result = 'FAILED'
        throw err
    }
}

node ('compiler-travis') {
    // Clean workspace before doing anything
    sh "sudo chmod -R 777 ."
    deleteDir()
    sh "echo 'Pull the built docker image for the PR'"
    withCredentials([usernamePassword(
        credentialsId: "bfndocker",
        usernameVariable: "DOCKER_USERNAME",
        passwordVariable: "DOCKER_PASSWORD"
    )]) {
        sh "docker pull barefootnetworks/bf-p4c-compilers:${image_tag}"
        sh "docker pull barefootnetworks/p4v:latest"
    }
    parallel (
        generate_metrics_switch_compile_only: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch profiles compilation for master'"
                    sh "docker run -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*switch_' -E 'smoketest|p4_14|glass' -LE 'METRICS'"
                    sh "echo 'Running some arista customer must passes that are excluded in Travis jobs'"
                    sh "docker run -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*arista*' -L 'CUST_MUST_PASS'"
                    sh "echo 'Running switch-14 and switch-16 tests for METRICS'"
                    withCredentials([usernamePassword(
                        credentialsId: "bfndocker",
                        usernameVariable: "DOCKER_USERNAME",
                        passwordVariable: "DOCKER_PASSWORD"
                    )]) {
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                        sh "docker pull barefootnetworks/compiler_metrics:stage"
                    }
                    sh "mkdir -p metrics_store"
                    metrics_cid = sh (
                        script: 'docker run --rm -t -d -w /bfn/compiler_metrics/database --entrypoint bash barefootnetworks/compiler_metrics:stage',
                        returnStdout: true
                    ).trim()
                    sh "echo 'metrics cid: ' $metrics_cid"
                    sh "docker cp ${metrics_cid}:/bfn/compiler_metrics/database/compiler_metrics.sqlite metrics_store/"
                    sh "docker tag barefootnetworks/bf-p4c-compilers:${image_tag} barefootnetworks/bf-p4c-compilers:${image_tag}_metrics"
                    def curr_pwd = pwd()
                    p4c_cid = sh (
                        script: "docker run --privileged --rm -t -d -v ${curr_pwd}/metrics_store:/mnt -w /bfn/bf-p4c-compilers/scripts/gen_reference_outputs --entrypoint bash barefootnetworks/bf-p4c-compilers:${image_tag}_metrics",
                        returnStdout: true
                    ).trim()
                    sh "echo 'p4c cid: ' $p4c_cid"
                    sh "docker exec ${p4c_cid} cp /mnt/compiler_metrics.sqlite /bfn/bf-p4c-compilers/scripts/gen_reference_outputs/database/"
                    sh "docker exec ${p4c_cid} python -u gen_ref_outputs.py --tests_csv profiles.csv --out_dir /bfn/bf-p4c-compilers/scripts/gen_reference_outputs/metrics_outputs/ --process_metrics --commit_sha ${image_tag}"
                    sh "docker container stop ${metrics_cid}"
                    sh "docker container stop ${p4c_cid}"
                }
            }
        },
        switch_msdc_and_switch_dc_basic_tests_cust2_and_stful_meters_hash_driven: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch PD tests for MSDC_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_msdc' -LE 'UNSTABLE'"

                    sh "echo 'Running switch PD tests for DC_BASIC_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_dc_basic' -LE 'UNSTABLE'"
                    sh "echo 'Running stful, meters and hash_driven tests'"
                    // Disable stful test (DRV-4189)
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R 'smoketest_programs_meters|smoketest_programs_hash_driven'"
                    sh "echo 'Running remaining customer must passes that are excluded in Travis jobs'"
                    sh "docker run -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/' -L 'CUST_MUST_PASS' -E 'arista'"
                }
            }
        },
        switch_16_tofino_tests_part_1: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running bf-switch bfrt tests for Tofino for X1 Profile'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_16_Tests_x1'"
                }
            }
        },
        switch_16_tofino_tests_part_2: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running bf-switch bfrt tests for Tofino for X2 Profile'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_16_Tests_x2'"
                }
            }
        },
        switch_16_tofino2_tests_part_1: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running bf-switch bfrt tests for Tofino2 for Y1 Profile'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino2/.*smoketest_switch_16_Tests_y1'"
                    sh "echo 'Running bf-switch compile_only for Tofino2 not covered in PTF'"
                    sh "docker run -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino2/.*smoketest_switch_16_compile' -LE 'PR_REG_PTF'"
                }
            }
        },
        switch_16_tofino2_tests_part_2_and_basic_ipv4: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running bf-switch bfrt tests for Tofino2 for Y2 Profile'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino2/.*smoketest_switch_16_Tests_y2'"
                    sh "echo 'Running basic_ipv4 tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R 'smoketest_programs_basic_ipv4'"
                }
            }
        },
        travis_tofino_part_1: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running tofino part 1 tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/' -E 'smoketest|/programs|/internal_p4_14|p4testgen|tofino/switch_|c2_COMPILER|c2/COMPILER|p4_16_programs|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|ptf/digest.p4|digest-std-p4runtime' -LE 'GTS_WEEKLY|NON_PR_TOFINO'"
                }
            }
        },
        travis_tofino_part_2: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running tofino part 2 tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/(.*programs|.*internal_p4_14)' -E 'TestRealData|_basic_ipv4|_stful|_meters|_hash_driven|_dkm|_exm_smoke_test|_exm_direct_|_exm_direct_1_|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|perf_test_alpm|entry_read_from_hw'"
                }
            }
        },
        travis_tofino2: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running tofino2 tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino2|cpplint|gtest|test_p4c_driver' -E 'ignore_test_|smoketest|p4_16_programs_tna_exact_match|p4_16_programs_tna_meter_lpf_wred|/p4_16/customer/extreme/p4c-1([^3]|3[^1]).*|/dkm/|entry_read_from_hw|/p4_14/stf/decaf_9.*|ptf/digest.p4'"
                }
            }
        },
        travis_tofino3: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running tofino3 tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino3' -LE 'ptf'"
                }
            }
        },
        p4o: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running p4 obfuscator tests'"
                    sh "mkdir -p p4o_regression"
                    def bf_p4c_cid = ""
                    bf_p4c_cid = sh (
                        script: "docker run --privileged --rm -t -d -w /bfn/bf-p4c-compilers/build/p4c --entrypoint bash barefootnetworks/bf-p4c-compilers:${image_tag}",
                        returnStdout: true
                    ).trim()
                    sh "echo 'bf_p4c_cid: ' $bf_p4c_cid"
                    sh "docker cp ${bf_p4c_cid}:/bfn/bf-p4c-compilers/build p4o_regression/"
                    sh "docker tag barefootnetworks/p4v:latest barefootnetworks/p4v:p4o_regression"
                    try {
                        def p4o_pwd = pwd()
                        def p4v_cid = ""
		        p4v_cid = sh (
                            script: "docker run --privileged --rm -t -d -v ${p4o_pwd}/p4o_regression/build:/bfn/bf-p4c-compilers/build -w /bfn/p4v/mutine/obfuscator/bin/scripts --entrypoint bash barefootnetworks/p4v:p4o_regression",
                            returnStdout: true
                        ).trim()
                        sh "echo 'p4v_cid : ' $p4v_cid"
                        sh "docker exec ${p4v_cid} python3 -u main.py -t compiler -r serial -f tests.csv"
                        sh "docker container stop ${bf_p4c_cid}"
                        sh "docker container stop ${p4v_cid}"
                    } catch (err) {
                        sh "echo 'p4o regression has failed'"
                    }
                }
            }
        },
        installed_p4c_tests: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running driver tests on installed p4c'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/scripts barefootnetworks/bf-p4c-compilers:${image_tag} python3 -u test_p4c_driver.py -j 4 --print-on-failure --compiler '/usr/local/bin/p4c'"
                }
            }
        }
    )
}


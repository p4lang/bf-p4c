node ('compiler || compiler-svr4') {
    sh "echo 'Building docker image for PR'"
    // Clean workspace before doing anything
    deleteDir()
    environment {
        def image_tag = ""
    }
    try {
        stage ('Checkout') {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Checking out build'"
                    checkout scm
                    image_tag = sh (
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    sh "echo 'image tag: ' $image_tag"
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
                            sh "docker build -f Dockerfile.tofino -t bf-p4c-compilers_${image_tag} --build-arg IMAGE_TYPE=test --build-arg MAKEFLAGS=j32 ."
                            sh "echo 'Tag and push docker image'"
                            sh "docker tag bf-p4c-compilers_${image_tag} barefootnetworks/bf-p4c-compilers:${image_tag}"
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

node ('compiler-svr1 || master') {
    sh "echo 'Pull the built docker image for the PR'"
    withCredentials([usernamePassword(
        credentialsId: "bfndocker",
        usernameVariable: "DOCKER_USERNAME",
        passwordVariable: "DOCKER_PASSWORD"
    )]) {
        sh "docker pull barefootnetworks/bf-p4c-compilers:${image_tag}"
    }
    parallel (
        switch_compile_only: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch profiles compilation for master'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*switch_' -E 'smoketest|8.4|p4_14'"
                    sh "echo 'Running switch profiles compilation for rel_8_4'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*switch_8.4_' -E 'smoketest'"
                }
            }
        },
        switch_8_4_msdc_and_switch_16_tests: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch PD tests for MSDC_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_8.4_msdc'"
                    sh "echo 'Running bf-switch bfrt tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_16'"
                }
            }
        },
        switch_8_4_dc_basic_tests: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch PD tests for DC_BASIC_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_8.4_dc_basic'"
                }
            }
        },
        travis_backup: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running tofino PTF tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/' -E 'smoketest|/programs|p4testgen|tofino/switch_|p4_16_programs_tna_ternary_match|p4_16_programs_tna_exact_match'
                    sh "echo 'Running tofino PTF tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_PARALLEL_LEVEL=4 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino2|cpplint|gtest|test_p4c_driver' -E 'smoketest'
                }
            }
        }
        //switch_8_4_ent_dc_general_tests: {
        //    ansiColor('xterm') {
        //        timestamps {
        //            sh "echo 'Running switch PD tests for ENT_DC_GENERAL_PROFILE_BRIG'"
        //            sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_8.4_ent_dc_general'"
        //        }
        //    }
        //}
    )
}

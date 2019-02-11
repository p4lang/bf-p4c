node ('compiler || compiler-svr4') {
    sh "echo 'Building docker image for PR'"
    // Clean workspace before doing anything
    deleteDir()
    environment {
        def image_tag = ""
        def model_cid = ""
        def p4c_cid = ""
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
                            // Update switch.p4-16 to the latest known working refpoint
                            switch_16_repo = 'p4-tests/p4_16/switch_16'
                            switch_16_branch = 'p4c/working-top'
                            sh "git -C $switch_16_repo fetch origin $switch_16_branch && git -C $switch_16_repo checkout $switch_16_branch"
                            sh "echo 'Using switch_16: ' && git -C p4-tests/p4_16/switch_16 log HEAD^..HEAD"
                            sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                            sh "docker build -f docker/Dockerfile.tofino -t bf-p4c-compilers_${image_tag} --build-arg IMAGE_TYPE=test --build-arg MAKEFLAGS=j16 ."
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
        switch_compile_only_and_stful_meters_hash_driven: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch profiles compilation for master'"
                    sh "docker run -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*switch_' -E 'smoketest|8.5|p4_14|glass'"
                    sh "echo 'Running switch profiles compilation for rel_8_5'"
                    sh "docker run -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*switch_8.5_' -E 'smoketest'"
                    sh "echo 'Running stful and meters tests'"
                    sh "mkdir -p docker_store"
                    model_cid = sh (
                        script: 'docker run --rm -t -d -w /usr/local/bin --entrypoint bash barefootnetworks/model:tofino_prog',
                        returnStdout: true
                    ).trim()
                    sh "echo 'model cid: ' $model_cid"
                    sh "docker cp ${model_cid}:/usr/local/bin/tofino-model docker_store/"
                    sh "docker tag barefootnetworks/bf-p4c-compilers:${image_tag} barefootnetworks/bf-p4c-compilers:${image_tag}_prog"
                    def curr_pwd = pwd()
                    p4c_cid = sh (
                        script: "docker run --privileged --rm -t -d -v ${curr_pwd}/docker_store:/mnt -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' --entrypoint bash barefootnetworks/bf-p4c-compilers:${image_tag}_prog",
                        returnStdout: true
                    ).trim()
                    sh "echo 'p4c cid: ' $p4c_cid"
                    sh "docker exec ${p4c_cid} cp /mnt/tofino-model /usr/local/bin/"
                    sh "docker exec ${p4c_cid} ctest -R 'smoketest_programs_stful|smoketest_programs_meters|smoketest_programs_hash_driven'"
                    sh "docker container stop ${model_cid}"
                    sh "docker container stop ${p4c_cid}"
                }
            }
        },
        switch_8_5_msdc_and_switch_16_tests: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch PD tests for MSDC_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_8.5_msdc'"

                    sh "echo 'Running bf-switch bfrt tests for Tofino'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_16'"

                    sh "echo 'Running bf-switch bfrt tests for Tofino2'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino2/.*smoketest_switch_16'"
                }
            }
        },
        switch_8_5_dc_basic_tests: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch PD tests for DC_BASIC_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_8.5_dc_basic'"
                }
            }
        },
        switch_8_5_ent_dc_general_tests_and_basic_ipv4: {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch PD tests for ENT_DC_GENERAL_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R '^tofino/.*smoketest_switch_8.5_ent_dc_general'"
                    sh "echo 'Running basic_ipv4 tests'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' barefootnetworks/bf-p4c-compilers:${image_tag} ctest -R 'smoketest_programs_basic_ipv4'"
                }
            }
        }
    )
}

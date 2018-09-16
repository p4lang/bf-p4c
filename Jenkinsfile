node {
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
                    sh "git submodule update --init --recursive"
                    image_tag = sh (
                        script: 'git rev-parse --short HEAD',
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
                    }
                    sh "docker build -f Dockerfile.tofino -t bf-p4c-compilers_${image_tag} --build-arg IMAGE_TYPE=test --build-arg MAKEFLAGS=j16 ."
                }
            }
        }
        stage ('Tests') {
            parallel (
                switch_compile_only: {
                    try {
                        stage ('switch_master_profiles') {
                            ansiColor('xterm') {
                                timestamps {
                                    sh "echo 'Running switch profiles compilation for master'"
                                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' bf-p4c-compilers_${image_tag} ctest -R '^tofino/.*switch_' -E 'smoketest|8.3|8.4|p4_14'"
                                }
                            }
                        }
                        stage ('switch_8.3_profiles') {
                            ansiColor('xterm') {
                                timestamps {
                                    sh "echo 'Running switch profiles compilation for rel_8_3'"
                                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' bf-p4c-compilers_${image_tag} ctest -R '^tofino/.*switch_8.3_' -E 'smoketest'"
                                }
                            }
                        }
                        // TODO: Add switch 8.4 profiles compile only (currently switch and switch-8.4 submodules are pointing to the same ref, so not added)
                    } catch (err) {
                        sh "echo 'Swith profiles compile_only failed'"
                        currentBuild.result = 'FAILED'
                        throw err
                    }
                },
                switch_8_4_spine_dtel_int_tests: {
                    ansiColor('xterm') {
                        timestamps {
                            sh "echo 'Running switch PD tests for MSDC_SPINE_DTEL_INT_PROFILE_BRIG'"
                            sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' bf-p4c-compilers_${image_tag} ctest -R '^tofino/.*smoketest_switch_8.4_spine_dtel_int'"
                        }
                    }
                },
                switch_8_4_dc_basic_tests: {
                    ansiColor('xterm') {
                        timestamps {
                            sh "echo 'Running switch PD tests for DC_BASIC_PROFILE_BRIG'"
                            sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' bf-p4c-compilers_${image_tag} ctest -R '^tofino/.*smoketest_switch_8.4_dc_basic'"
                        }
                    }
                },
                switch_8_4_ent_dc_general_tests: {
                    ansiColor('xterm') {
                        timestamps {
                            sh "echo 'Running switch PD tests for ENT_DC_GENERAL_PROFILE_BRIG'"
                            sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e NUM_HUGEPAGES=512 -e CTEST_OUTPUT_ON_FAILURE='true' bf-p4c-compilers_${image_tag} ctest -R '^tofino/.*smoketest_switch_8.4_ent_dc_general'"
                        }
                    }
                }
            )
        }
    } catch (err) {
        currentBuild.result = 'FAILED'
        throw err
    } finally {
        sh "echo 'Remove docker image'"
        sh "docker rmi -f bf-p4c-compilers_${image_tag}"
    }
}

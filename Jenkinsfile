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
                    sh "docker build -f Dockerfile.tofino -t bf-p4c-compilers_${image_tag} --build-arg IMAGE_TYPE=test --build-arg MAKEFLAGS=j4 ."
                }
            }
        }
        stage ('Tests') {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Running switch PD tests for MSDC_PROFILE_BRIG'"
                    sh "docker run --privileged -w /bfn/bf-p4c-compilers/build/p4c -e CTEST_OUTPUT_ON_FAILURE='true' bf-p4c-compilers_${image_tag} ctest -R '^tofino.*smoketest_switch_msdc'"
                }
            }
        }
        stage ('Cleanup') {
            ansiColor('xterm') {
                timestamps {
                    sh "echo 'Remove docker image'"
                    sh "docker rmi -f bf-p4c-compilers_${image_tag}"
                }
            }
        }
    } catch (err) {
        currentBuild.result = 'FAILED'
        throw err
    }
}

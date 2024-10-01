/**
 * Copyright (C) 2024 Intel Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.  See the License for the specific language governing permissions
 * and limitations under the License.
 *
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * Libraries contain reusabile snippets that can be reused across multiple projects.
 */
@Library('bf-jenkins-utils@master')_

node {
    // kill any previous runs of the same branch that may be in progress
    stopPreviousRuns(this)
}

// Intel CaaS (AMR)
DOCKER_CREDENTIALS = "bfndocker-caas"
DOCKER_REGISTRY = "amr-registry.caas.intel.com"
DOCKER_PROJECT = "${DOCKER_REGISTRY}/bxd-sw"

BRANCH_ID = "${env.BRANCH_NAME.toLowerCase().replaceAll("/","_")}"

node ('compiler-nodes') {
    // Clean workspace before doing anything
    sh "sudo chmod -R 777 ."
    deleteDir()
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

            stage ('Setup build') {
                echo "Initializing bf-p4c-compilers submodules"
                sh "git submodule update --init --recursive"
            }

            stage ('Build documentation and Publish') {
                echo 'Building and Extracting documentation'
                def curr_pwd = pwd()
                sh """
                    mkdir -p doc
		    make -Cdocker test-build clean \
			    BUILD_ARGS="-v ${curr_pwd}/doc:/mnt" \
			    BUILD_SCRIPT="bash -c \
				'./bootstrap_bfn_compilers.sh && \
                                cd build && \
                                make doc && \
                                tar czf /mnt/html.tar.gz html'"

                """

                echo 'Archiving artifact'
                archiveArtifacts(
                    artifacts: 'doc/html.tar.gz'
                )
            }

        }
    }
}

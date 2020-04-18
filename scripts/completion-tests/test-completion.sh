#!/usr/bin/env bash
#
# Copyright The Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script runs completion tests in different environments and different shells.

# Fail as soon as there is an error
set -e
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# TODO: this is redeclared, but shouldnt have to be?
# getting error "scripts/completion-tests/test-completion.sh: line 23: set_shell_debug_level: command not found"
set_shell_debug_level()
{
    set +x
    if [ $ROBOT_DEBUG_LEVEL -ge $1 ]; then
       set -x
    fi
}
export -f set_shell_debug_level

set_shell_debug_level 2

BINARY_NAME=helm
BINARY_ROOT=${ROBOT_HELM_PATH:-${SCRIPT_DIR}/../../../helm/bin}
BINARY_PATH_DOCKER=${BINARY_ROOT}/../_dist/linux-amd64
BINARY_PATH_LOCAL=${BINARY_ROOT}

if [ -z $(which docker) ]; then
  echo "Missing 'docker' client which is required for these tests";
  exit 2;
fi

# Only use the -d flag for mktemp as many other flags don't
# work on every plateform
export COMP_DIR=$(mktemp -d ${ROBOT_OUTPUT_DIR}/helm-acceptance-completion.XXXXXX)
trap "rm -rf ${COMP_DIR}" EXIT

COMP_SCRIPT_NAME=setup-completion.sh
COMP_SCRIPT=${COMP_DIR}/${COMP_SCRIPT_NAME}

rm -rf ${COMP_DIR}
mkdir -p ${COMP_DIR}/lib
mkdir -p ${COMP_DIR}/bin
cp ${SCRIPT_DIR}/${COMP_SCRIPT_NAME} ${COMP_DIR}

cp ${SCRIPT_DIR}/run-completionTests-common.sh ${COMP_DIR}
cp ${SCRIPT_DIR}/run-completionTests.bash ${COMP_DIR}
cp ${SCRIPT_DIR}/run-completionTests.zsh ${COMP_DIR}
cp ${SCRIPT_DIR}/run-completionTests.fish ${COMP_DIR}

cp ${SCRIPT_DIR}/completionTests-common.sh ${COMP_DIR}
cp ${SCRIPT_DIR}/completionTests.bash ${COMP_DIR}
cp ${SCRIPT_DIR}/completionTests.zsh ${COMP_DIR}
cp ${SCRIPT_DIR}/completionTests.fish ${COMP_DIR}

cp ${SCRIPT_DIR}/releases.yaml ${COMP_DIR}

if [[ "${GITHUB_SHA}" == "" ]]; then
  CHECK_BINARY_PATH="$(cd ${BINARY_PATH_DOCKER} && pwd)/${BINARY_NAME}"
  if [[ ! -f ${CHECK_BINARY_PATH} ]] && [[ -L ${CHECK_BINARY_PATH} ]]; then
      echo "These tests require a helm binary located at ${CHECK_BINARY_PATH}"
      echo "Hint: Run 'make build-cross' in a clone of helm repo"
      exit 2
  fi
  cp ${CHECK_BINARY_PATH} ${COMP_DIR}/bin
else
  echo "Running on GitHub Actions CI - using system-wide Helm 3 binary."
  cp $(which helm-docker) ${COMP_DIR}/bin/helm
fi

# Now run all tests, even if there is a failure.
# But remember if there was any failure to report it at the end.
set +e
GOT_FAILURE=0
trap "GOT_FAILURE=1" ERR

########################################
# Bash 4 completion tests
########################################
BASH4_IMAGE=completion-bash4

echo;echo;
docker build -t ${BASH4_IMAGE} - <<- EOF
   FROM bash:4.4
   RUN apk update && apk add bash-completion ca-certificates
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} \
           -e ROBOT_HELM_V3=${ROBOT_HELM_V3} \
           -e ROBOT_DEBUG_LEVEL=${ROBOT_DEBUG_LEVEL} \
           -e COMP_DIR=${COMP_DIR} \
           ${BASH4_IMAGE} ${COMP_SCRIPT} bash

########################################
# Bash 3.2 completion tests
########################################
# We choose version 3.2 because we want some Bash 3 version and 3.2
# is the version by default on MacOS.  So testing that version
# gives us a bit of coverage for MacOS.
BASH3_IMAGE=completion-bash3

echo;echo;
docker build -t ${BASH3_IMAGE} - <<- EOF
   FROM bash:3.2
   RUN apk update && apk add ca-certificates
   # For bash 3.2, the bash-completion package required is version 1.3
   RUN mkdir /usr/share/bash-completion && \
       wget -qO - https://github.com/scop/bash-completion/archive/1.3.tar.gz | \
            tar xvz -C /usr/share/bash-completion --strip-components 1 bash-completion-1.3/bash_completion
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} \
           -e BASH_COMPLETION=/usr/share/bash-completion \
           -e ROBOT_HELM_V3=${ROBOT_HELM_V3} \
           -e ROBOT_DEBUG_LEVEL=${ROBOT_DEBUG_LEVEL} \
           -e COMP_DIR=${COMP_DIR} \
           ${BASH3_IMAGE} ${COMP_SCRIPT} bash

########################################
# Bash centos completion tests
# https://github.com/helm/helm/pull/7304
########################################
BASH_IMAGE=completion-bash-centos

echo;echo;
docker build -t ${BASH_IMAGE} - <<- EOF
   FROM centos
   RUN yum install -y bash-completion which
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} \
           -e ROBOT_HELM_V3=${ROBOT_HELM_V3} \
           -e ROBOT_DEBUG_LEVEL=${ROBOT_DEBUG_LEVEL} \
           -e COMP_DIR=${COMP_DIR} \
           ${BASH_IMAGE} ${COMP_SCRIPT} bash

########################################
# Zsh completion tests
########################################
ZSH_IMAGE=completion-zsh

echo;echo;
docker build -t ${ZSH_IMAGE} - <<- EOF
   FROM zshusers/zsh:5.7
   # This will install the SSL certificates necessary for helm repo update to work
   RUN apt-get update && apt-get install -y wget
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} \
           -e ROBOT_HELM_V3=${ROBOT_HELM_V3} \
           -e ROBOT_DEBUG_LEVEL=${ROBOT_DEBUG_LEVEL} \
           -e COMP_DIR=${COMP_DIR} \
           ${ZSH_IMAGE} ${COMP_SCRIPT} zsh

########################################
# Zsh alpine/busybox completion tests
# https://github.com/helm/helm/pull/6327
########################################
ZSH_IMAGE=completion-zsh-alpine

echo;echo;
docker build -t ${ZSH_IMAGE} - <<- EOF
   FROM alpine
   RUN apk update && apk add bash zsh ca-certificates
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} \
           -e ROBOT_HELM_V3=${ROBOT_HELM_V3} \
           -e ROBOT_DEBUG_LEVEL=${ROBOT_DEBUG_LEVEL} \
           -e COMP_DIR=${COMP_DIR} \
           ${ZSH_IMAGE} ${COMP_SCRIPT} zsh

########################################
# Fish completion tests
########################################
FISH_IMAGE=completion-fish

docker build -t ${FISH_IMAGE} - <<- EOF
   FROM centos
   RUN cd /etc/yum.repos.d/ && \
       curl -O https://download.opensuse.org/repositories/shells:/fish/CentOS_8/shells:fish.repo && \
       yum install -y fish which
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} \
           -e ROBOT_HELM_V3=${ROBOT_HELM_V3} \
           -e ROBOT_DEBUG_LEVEL=${ROBOT_DEBUG_LEVEL} \
           -e COMP_DIR=${COMP_DIR} \
           ${FISH_IMAGE} ${COMP_SCRIPT} fish

########################################
# MacOS completion tests
########################################
# Since we can't use Docker to test MacOS,
# we run the MacOS tests locally when possible.
if [ "$(uname)" == "Darwin" ]; then
   echo;echo
   echo "===================================================="
   echo "Attempting local completion tests on Darwin"
   echo "===================================================="

   # Copy the local helm to use
   if ! cp ${BINARY_PATH_LOCAL}/${BINARY_NAME} ${COMP_DIR}/bin ; then
       echo "Cannot find ${BINARY_NAME} under ${BINARY_PATH_LOCAL}/${BINARY_NAME} although it is what we need to test."
       exit 1
   fi

   if which bash>/dev/null && [ -f /usr/local/etc/bash_completion ]; then
      echo;echo;
      echo "Completion tests for bash running locally"
      ${COMP_SCRIPT} bash
   fi

   if which zsh>/dev/null; then
      echo;echo;
      echo "Completion tests for zsh running locally"
      ${COMP_SCRIPT} zsh
   fi

   if which fish>/dev/null; then
      echo;echo;
      echo "Completion tests for fish running locally"
      ${COMP_SCRIPT} fish
   fi
fi

# Indicate if anything failed during the run
exit ${GOT_FAILURE}

#!/bin/bash -ex
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

export KUBECTL_VERSION="v1.16.1"
export KIND_VERSION="v0.5.1"

rm -rf bin/
mkdir -p bin/
export PATH="${PWD}/bin:${HOME}/.local/bin:${PATH}"
export GITHUB_SHA="${GITHUB_SHA:-latest}"

# Build helm from source
which helm || true
mkdir -p /tmp/gopath/src/helm.sh
pushd /tmp/gopath/src/helm.sh
git clone https://github.com/helm/helm.git -b master
pushd helm/
GOPATH=/tmp/gopath make build build-cross
popd
popd
mv /tmp/gopath/src/helm.sh/helm/bin/helm bin/helm
mv /tmp/gopath/src/helm.sh/helm/_dist/linux-amd64/helm bin/helm-docker
helm version
which helm

# These tools appear to be in the GitHub "ubuntu-latest" environment, but not in
# the ubuntu:latest image from Docker Hub
if ! [[ -x "$(command -v curl)" || -x "$(command -v pip3)" || -x "$(command -v docker)" ]]; then
  apt-get update
  apt-get install -y apt-transport-https ca-certificates gnupg-agent software-properties-common curl python3-pip

  # Docker install
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce
fi
if ! [[ -x "$(command -v pip)" ]]; then
  ln -sf $(which pip3) bin/pip
fi

# Install kubectl
which kubectl || true
curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl bin/kubectl
kubectl version --client
which kubectl

# Install kind
which kind || true
curl -LO https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64
chmod +x kind-linux-amd64
mv kind-linux-amd64 bin/kind
which kind

# Install virtualenv
which virtualenv || true
pip3 install --user virtualenv
virtualenv --version
which virtualenv

export ROBOT_OUTPUT_DIR="${PWD}/acceptance-testing-reports/${GITHUB_SHA}"
rm -rf ${ROBOT_OUTPUT_DIR}
mkdir -p ${ROBOT_OUTPUT_DIR}
trap "rm -rf ${ROBOT_OUTPUT_DIR}/.venv/" EXIT

# Run
make acceptance

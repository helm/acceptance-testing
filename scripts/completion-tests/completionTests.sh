#!bash
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

# This script tests different scenarios of completion.  The tests can be
# run by sourcing this file from a bash shell or a zsh shell.

source /tmp/helm-acceptance-shell-completion-tests/lib/completionTests-base.sh

# Don't use the new source <() form as it does not work with bash v3
source /dev/stdin <<- EOF
   $(helm completion $SHELL_TYPE)
EOF

# Helm setup
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-/tmp/helm/cache} && mkdir -p ${XDG_CACHE_HOME}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-/tmp/helm/config} && mkdir -p ${XDG_CONFIG_HOME}
export XDG_DATA_HOME=${XDG_DATA_HOME:-/tmp/helm/data} && mkdir -p ${XDG_DATA_HOME}

# Setup some repos to allow testing completion of the helm repo command
# We inject the content of the repositories.yaml file directly to avoid requiring
# an internet connection if we were to use 'helm repo add'
mkdir -p ${XDG_CONFIG_HOME}/helm
cat > ${XDG_CONFIG_HOME}/helm/repositories.yaml << EOF
apiVersion: v1
generated: "2019-08-11T22:28:44.841141-04:00"
repositories:
- name: stable
  url: https://kubernetes-charts.storage.googleapis.com
- name: test1
  url: https://charts.example.com
- name: test2
  url: https://charts2.example.com
EOF
helm repo list

# Setup some plugins to allow testing completion of the helm plugin command
# We inject the content of different plugin.yaml files directly to avoid having
# to install a real plugin which can take a long time.
PLUGIN_ROOT=${XDG_DATA_HOME}/helm/plugins

PLUGIN_DIR=${PLUGIN_ROOT}/helm-template
mkdir -p ${PLUGIN_DIR}
cat > ${PLUGIN_DIR}/plugin.yaml << EOF
name: "template"
version: "2.5.1+2"
description: "Render templates on the local client."
EOF

PLUGIN_DIR=${PLUGIN_ROOT}/helm-push
mkdir -p ${PLUGIN_DIR}
cat > ${PLUGIN_DIR}/plugin.yaml << EOF
name: "push"
version: "0.7.1"
description: "Push chart package to ChartMuseum"
EOF

PLUGIN_DIR=${PLUGIN_ROOT}/helm-push-artifactory
mkdir -p ${PLUGIN_DIR}
cat > ${PLUGIN_DIR}/plugin.yaml << EOF
name: "push-artifactory"
version: "0.3.0"
description: "Push helm charts to artifactory"
EOF
helm plugin list

#####################
# Static completions
#####################

# No need to test every command, as completion is handled
# automatically by Cobra.
# We focus on some smoke tests for the Cobra-handled completion
# and also on code specific to this project.

# Basic first level commands (static completion)
_completionTests_verifyCompletion "helm stat" "status"
_completionTests_verifyCompletion "helm status" "status"
_completionTests_verifyCompletion "helm lis" "list"
_completionTests_verifyCompletion "helm r" "repo rollback"
_completionTests_verifyCompletion "helm re" "repo"

# Basic second level commands (static completion)
_completionTests_verifyCompletion "helm get " "hooks manifest values"
_completionTests_verifyCompletion "helm get h" "hooks"
_completionTests_verifyCompletion "helm completion " "bash zsh"
_completionTests_verifyCompletion "helm completion z" "zsh"

# Completion of flags
#_completionTests_verifyCompletion ZFAIL "helm --kube-con" "--kube-context= --kube-context"
#_completionTests_verifyCompletion ZFAIL "helm --kubecon" "--kubeconfig= --kubeconfig"
#_completionTests_verifyCompletion ZFAIL "helm --name" "--namespace= --namespace"
_completionTests_verifyCompletion "helm -v" "-v"
#_completionTests_verifyCompletion ZFAIL "helm --v" "--v= --vmodule= --v --vmodule"

# Completion of commands while using flags
_completionTests_verifyCompletion "helm --kube-context prod sta" "status"
_completionTests_verifyCompletion "helm --namespace mynamespace get h" "hooks"
#_completionTests_verifyCompletion KFAIL "helm -v get " "hooks manifest values"
#_completionTests_verifyCompletion ZFAIL "helm --kubeconfig=/tmp/config lis" "list"
#_completionTests_verifyCompletion ZFAIL "helm ---namespace mynamespace get " "hooks manifest values"
#_completionTests_verifyCompletion ZFAIL "helm get --name" "--namespace= --namespace"
#_completionTests_verifyCompletion ZFAIL "helm get hooks --kubec" "--kubeconfig= --kubeconfig"

# Alias completion
# Does not work.
#_completionTests_verifyCompletion KFAIL "helm ls" "ls"
#_completionTests_verifyCompletion KFAIL "helm dependenci" "dependencies"

#####################
# Dynamic completions
#####################

# For the repo command
_completionTests_verifyCompletion "helm repo remove " "stable test1 test2"
_completionTests_verifyCompletion "helm repo remove test" "test1 test2"

# For the plugin command
_completionTests_verifyCompletion "helm plugin remove " "template push push-artifactory"
_completionTests_verifyCompletion "helm plugin remove pu" "push push-artifactory"
_completionTests_verifyCompletion "helm plugin update " "template push push-artifactory"
_completionTests_verifyCompletion "helm plugin update pus" "push push-artifactory"

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

export PATH=/tmp/helm-acceptance-shell-completion-tests/bin:$PATH

# Don't use the new source <() form as it does not work with bash v3
source /dev/stdin <<- EOF
   $(helm completion $SHELL_TYPE)
EOF

# Helm setup
HELM_ROOT=/tmp/helm-acceptance-tests-helm-config
if [ ! -z ${ROBOT_HELM_V3} ]; then
    export XDG_CACHE_HOME=${XDG_CACHE_HOME:-${HELM_ROOT}/cache} && mkdir -p ${XDG_CACHE_HOME}
    export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-${HELM_ROOT}/config} && mkdir -p ${XDG_CONFIG_HOME}
    export XDG_DATA_HOME=${XDG_DATA_HOME:-${HELM_ROOT}/data} && mkdir -p ${XDG_DATA_HOME}

    REPO_ROOT=${XDG_CONFIG_HOME}/helm
    PLUGIN_ROOT=${XDG_DATA_HOME}/helm/plugins
else
    export HELM_HOME=${HELM_ROOT}
    helm init --client-only

    REPO_ROOT=${HELM_HOME}/repository
    PLUGIN_ROOT=${HELM_HOME}/plugins
fi

# Setup some repos to allow testing completion of the helm repo command
# We inject the content of the repositories.yaml file directly to avoid requiring
# an internet connection if we were to use 'helm repo add'
mkdir -p ${REPO_ROOT}
cat > ${REPO_ROOT}/repositories.yaml << EOF
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
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "helm r" "repo rollback"
    _completionTests_verifyCompletion "helm re" "repo"
else
    _completionTests_verifyCompletion "helm r" "repo reset rollback"
    _completionTests_verifyCompletion "helm re" "repo reset"
fi

# Basic second level commands (static completion)
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "helm get " "hooks manifest values"
else
    _completionTests_verifyCompletion "helm get " "hooks manifest notes values"
fi
_completionTests_verifyCompletion "helm get h" "hooks"
_completionTests_verifyCompletion "helm completion " "bash zsh"
_completionTests_verifyCompletion "helm completion z" "zsh"

# Completion of flags
_completionTests_verifyCompletion ZFAIL "helm --kube-con" "--kube-context= --kube-context"
_completionTests_verifyCompletion ZFAIL "helm --kubecon" "--kubeconfig= --kubeconfig"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "helm -v" "-v"
    _completionTests_verifyCompletion ZFAIL "helm --v" "--v= --vmodule= --v --vmodule"
    _completionTests_verifyCompletion ZFAIL "helm --name" "--namespace= --namespace"
fi

# Completion of commands while using flags
_completionTests_verifyCompletion "helm --kube-context prod sta" "status"
_completionTests_verifyCompletion "helm --kubeconfig=/tmp/config lis" "list"
_completionTests_verifyCompletion ZFAIL "helm get hooks --kubec" "--kubeconfig= --kubeconfig"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "helm --namespace mynamespace get h" "hooks"
    _completionTests_verifyCompletion KFAIL "helm -v get " "hooks manifest values"
    _completionTests_verifyCompletion ZFAIL "helm get --name" "--namespace= --namespace"
fi

# Alias completion
# Does not work.
_completionTests_verifyCompletion KFAIL "helm ls" "ls"
_completionTests_verifyCompletion KFAIL "helm dependenci" "dependencies"

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

# For the global --kube-context flag
if [ ! -z ${ROBOT_HELM_V3} ]; then
    # Feature not available in v2
    _completionTests_verifyCompletion "helm --kube-context " "dev1 dev2 accept prod"
    _completionTests_verifyCompletion ZFAIL "helm --kube-context=" "dev1 dev2 accept prod"
    _completionTests_verifyCompletion "helm upgrade --kube-context " "dev1 dev2 accept prod"
    _completionTests_verifyCompletion "helm upgrade --kube-context d" "dev1 dev2"
fi
# For the global --namespace flag
if [ ! -z ${ROBOT_HELM_V3} ]; then
    # No namespace flag in v2
    _completionTests_verifyCompletion "helm --namespace " "casterly-rock white-harbor winterfell"
    _completionTests_verifyCompletion "helm --namespace w" "white-harbor winterfell"
    _completionTests_verifyCompletion ZFAIL "helm --namespace=w" "white-harbor winterfell"
    _completionTests_verifyCompletion "helm upgrade --namespace " "casterly-rock white-harbor winterfell"

    # With override flags
    _completionTests_verifyCompletion "helm --kubeconfig myconfig --namespace " "meereen myr volantis"
    _completionTests_verifyCompletion "helm --kubeconfig=myconfig --namespace " "meereen myr volantis"
    _completionTests_verifyCompletion "helm --kube-context mycontext --namespace " "braavos old-valyria yunkai"
    _completionTests_verifyCompletion "helm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
fi

# This must be the last call.  It allows to exit with an exit code
# that reflects the final status of all the tests.
_completionTests_exit

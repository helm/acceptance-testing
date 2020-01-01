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

source ${COMP_DIR}/lib/completionTests-base.sh

export PATH=${COMP_DIR}/bin:$PATH

# Don't use the new source <() form as it does not work with bash v3
source /dev/stdin <<- EOF
   $(helm completion $SHELL_TYPE)
EOF

# Helm setup
if [ ! -z ${ROBOT_HELM_V3} ]; then
    export XDG_CACHE_HOME=${COMP_DIR}/cache && rm -rf ${XDG_CACHE_HOME} && mkdir -p ${XDG_CACHE_HOME}
    export XDG_CONFIG_HOME=${COMP_DIR}/config && rm -rf ${XDG_CONFIG_HOME} && mkdir -p ${XDG_CONFIG_HOME}
    export XDG_DATA_HOME=${COMP_DIR}/data && rm -rf ${XDG_DATA_HOME} && mkdir -p ${XDG_DATA_HOME}

    REPO_ROOT=${XDG_CONFIG_HOME}/helm
    PLUGIN_ROOT=${XDG_DATA_HOME}/helm/plugins
else
    export HELM_HOME=${COMP_DIR}/.helm && rm -rf ${HELM_HOME} && mkdir -p ${HELM_HOME}
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
- name: zztest1
  url: https://charts.example.com
- name: zztest2
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
    _completionTests_verifyCompletion "helm get " "all hooks manifest notes values"
else
    _completionTests_verifyCompletion "helm get " "all hooks manifest notes values"
fi
_completionTests_verifyCompletion "helm get h" "hooks"
_completionTests_verifyCompletion "helm completion " "bash zsh"
_completionTests_verifyCompletion "helm completion z" "zsh"

# Completion of flags
if [ "$SHELL_TYPE" = bash ]; then
    _completionTests_verifyCompletion "helm --kube-con" "--kube-context= --kube-context"
    _completionTests_verifyCompletion "helm --kubecon" "--kubeconfig= --kubeconfig"
else
    _completionTests_verifyCompletion "helm --kube-con" "--kube-context --kube-context --kube-context"
    _completionTests_verifyCompletion "helm --kubecon" "--kubeconfig --kubeconfig --kubeconfig"
fi
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "helm -v" "-v"
    if [ "$SHELL_TYPE" = bash ]; then
        _completionTests_verifyCompletion "helm --v" "--v= --vmodule= --v --vmodule"
        _completionTests_verifyCompletion "helm --name" "--namespace= --namespace"
    else
        _completionTests_verifyCompletion "helm --v" "--v --vmodule --v --vmodule --v --vmodule"
        _completionTests_verifyCompletion "helm --name" "--namespace --namespace --namespace"
    fi
fi
# Completion of commands while using flags
_completionTests_verifyCompletion "helm --kube-context prod sta" "status"
_completionTests_verifyCompletion "helm --kubeconfig=/tmp/config lis" "list"
if [ "$SHELL_TYPE" = bash ]; then
    _completionTests_verifyCompletion "helm get hooks --kubec" "--kubeconfig= --kubeconfig"
else
    _completionTests_verifyCompletion "helm get hooks --kubec" "--kubeconfig --kubeconfig --kubeconfig"
fi
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "helm --namespace mynamespace get h" "hooks"
    _completionTests_verifyCompletion "helm -v 3 get " "all hooks manifest notes values"
    if [ "$SHELL_TYPE" = bash ]; then
        _completionTests_verifyCompletion "helm get --name" "--namespace= --namespace"
    else
        _completionTests_verifyCompletion "helm get --name" "--namespace --namespace --namespace"
    fi
fi

# Cobra command aliases are purposefully not completed
_completionTests_verifyCompletion "helm ls" ""
_completionTests_verifyCompletion "helm dependenci" ""

#####################
# Dynamic completions
#####################

# For the repo command
_completionTests_verifyCompletion "helm repo remove " "stable zztest1 zztest2"
_completionTests_verifyCompletion "helm repo remove zztest" "zztest1 zztest2"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    # Make sure completion works as expected when there are no repositories configured
    tmp=$XDG_CONFIG_HOME
    XDG_CONFIG_HOME='/invalid/path' _completionTests_verifyCompletion "helm repo remove " ""
    XDG_CONFIG_HOME=$tmp
fi

# For the plugin command
_completionTests_verifyCompletion "helm plugin uninstall " "template push push-artifactory"
_completionTests_verifyCompletion "helm plugin uninstall pu" "push push-artifactory"
_completionTests_verifyCompletion "helm plugin update " "template push push-artifactory"
_completionTests_verifyCompletion "helm plugin update pus" "push push-artifactory"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    # Make sure completion works as expected when there are no plugins
    tmp=$XDG_DATA_HOME
    XDG_DATA_HOME='/invalid/path' _completionTests_verifyCompletion "helm plugin uninstall " ""
    XDG_DATA_HOME=$tmp
fi

# For the global --kube-context flag
if [ ! -z ${ROBOT_HELM_V3} ]; then
    # Feature not available in v2
    _completionTests_verifyCompletion "helm --kube-context " "dev1 dev2 accept prod"
    _completionTests_verifyCompletion "helm upgrade --kube-context " "dev1 dev2 accept prod"
    _completionTests_verifyCompletion "helm upgrade --kube-context d" "dev1 dev2"
    if [ "$SHELL_TYPE" = bash ]; then
        _completionTests_verifyCompletion "helm --kube-context=" "dev1 dev2 accept prod"
    else
        _completionTests_verifyCompletion "helm --kube-context=" "--kube-context=dev1 --kube-context=dev2 --kube-context=accept --kube-context=prod"
    fi
fi

# For the global --namespace flag
if [ ! -z ${ROBOT_HELM_V3} ]; then
    # No namespace flag in v2
    _completionTests_verifyCompletion "helm --namespace " "casterly-rock white-harbor winterfell"
    _completionTests_verifyCompletion "helm --namespace w" "white-harbor winterfell"
    _completionTests_verifyCompletion "helm upgrade --namespace " "casterly-rock white-harbor winterfell"
    _completionTests_verifyCompletion "helm -n " "casterly-rock white-harbor winterfell"
    _completionTests_verifyCompletion "helm -n w" "white-harbor winterfell"
    _completionTests_verifyCompletion "helm upgrade -n " "casterly-rock white-harbor winterfell"

    if [ "$SHELL_TYPE" = bash ]; then
        _completionTests_verifyCompletion "helm --namespace=" "casterly-rock white-harbor winterfell"
        _completionTests_verifyCompletion "helm --namespace=w" "white-harbor winterfell"
        _completionTests_verifyCompletion "helm ugrade --namespace=w" "white-harbor winterfell"
        _completionTests_verifyCompletion "helm upgrade --namespace=" "casterly-rock white-harbor winterfell"
        _completionTests_verifyCompletion "helm -n=" "casterly-rock white-harbor winterfell"
        _completionTests_verifyCompletion "helm -n=w" "white-harbor winterfell"
        _completionTests_verifyCompletion "helm ugrade -n=w" "white-harbor winterfell"
        _completionTests_verifyCompletion "helm upgrade -n=" "casterly-rock white-harbor winterfell"
    else
        _completionTests_verifyCompletion "helm --namespace=" "--namespace=casterly-rock --namespace=white-harbor --namespace=winterfell"
        _completionTests_verifyCompletion "helm --namespace=w" "--namespace=white-harbor --namespace=winterfell"
        _completionTests_verifyCompletion "helm ugrade --namespace=w" "--namespace=white-harbor --namespace=winterfell"
        _completionTests_verifyCompletion "helm upgrade --namespace=" "--namespace=casterly-rock --namespace=white-harbor --namespace=winterfell"
        _completionTests_verifyCompletion "helm -n=" "-n=casterly-rock -n=white-harbor -n=winterfell"
        _completionTests_verifyCompletion "helm -n=w" "-n=white-harbor -n=winterfell"
        _completionTests_verifyCompletion "helm ugrade -n=w" "-n=white-harbor -n=winterfell"
        _completionTests_verifyCompletion "helm upgrade -n=" "-n=casterly-rock -n=white-harbor -n=winterfell"
    fi

    # With override flags
    _completionTests_verifyCompletion "helm --kubeconfig myconfig --namespace " "meereen myr volantis"
    _completionTests_verifyCompletion "helm --kubeconfig=myconfig --namespace " "meereen myr volantis"
    _completionTests_verifyCompletion "helm --kube-context mycontext --namespace " "braavos old-valyria yunkai"
    _completionTests_verifyCompletion "helm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
fi
# For the --output flag that applies to multiple commands
if [ ! -z ${ROBOT_HELM_V3} ]; then
    # Feature not available in v2

    # Also test that the list of outputs matches what the helm message gives.
    # This is an imperfect way of detecting if the output format list has changed, but
    # the completion wasn't updated to match.
    outputFormats=$(helm repo list -h 2>&1 | grep -- --output | cut -d: -f2 | cut -d '(' -f1 | sed s/,//g)
    _completionTests_verifyCompletion "helm repo list --output " "${outputFormats}"
    _completionTests_verifyCompletion "helm install --output " "${outputFormats}"
    _completionTests_verifyCompletion "helm history -o " "${outputFormats}"
    _completionTests_verifyCompletion "helm list -o " "${outputFormats}"
fi

# For completing specification of charts
if [ ! -z ${ROBOT_HELM_V3} ]; then
    tmpFiles="zztest2file files"
    touch $tmpFiles

    _completionTests_verifyCompletion "helm show values " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
    _completionTests_verifyCompletion "helm show values ht" "http:// https://"
    _completionTests_verifyCompletion "helm show values zz" "zztest1/ zztest2/ zztest2file"
    _completionTests_verifyCompletion "helm show values zztest2" "zztest2/ zztest2file"
    _completionTests_verifyCompletion "helm show values zztest2f" ""
    _completionTests_verifyCompletion "helm show values stable/yyy" ""
    _completionTests_verifyCompletion KFAIL "helm show values stable/z" "stable/zeppelin stable/zetcd"
    _completionTests_verifyCompletion "helm show values fil" "file:// files"

    _completionTests_verifyCompletion "helm show chart zz" "zztest1/ zztest2/ zztest2file"
    _completionTests_verifyCompletion "helm show readme zz" "zztest1/ zztest2/ zztest2file"
    _completionTests_verifyCompletion "helm show values zz" "zztest1/ zztest2/ zztest2file"

    _completionTests_verifyCompletion "helm pull " "zztest1/ zztest2/ stable/ file:// http:// https://"
    _completionTests_verifyCompletion "helm pull zz" "zztest1/ zztest2/"

    _completionTests_verifyCompletion "helm install name " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
    _completionTests_verifyCompletion "helm install name zz" "zztest1/ zztest2/ zztest2file"
    _completionTests_verifyCompletion KFAIL "helm install name stable/z" "stable/zeppelin stable/zetcd"

    _completionTests_verifyCompletion "helm template name " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
    _completionTests_verifyCompletion "helm template name zz" "zztest1/ zztest2/ zztest2file"
    _completionTests_verifyCompletion KFAIL "helm template name stable/z" "stable/zeppelin stable/zetcd"

    _completionTests_verifyCompletion "helm upgrade release " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
    _completionTests_verifyCompletion "helm upgrade release zz" "zztest1/ zztest2/ zztest2file"
    _completionTests_verifyCompletion KFAIL "helm upgrade release stable/z" "stable/zeppelin stable/zetcd"

    if [ "$SHELL_TYPE" = zsh ]; then
        _completionTests_verifyCompletion "helm show values stab" "stable/ stable/."
    else
        _completionTests_verifyCompletion "helm show values stab" "stable/"
    fi

    \rm $tmpFiles
fi

##############################################################
# Completion with helm called through an alias or using a path
##############################################################

# We want to specify a different helm for completion than the one
# that is found on the PATH variable.
# This is particularly valuable to check that dynamic completion
# uses the correct location for helm.

# Copy helm to a location that is not on PATH
TMP_HELM_DIR=$(mktemp -d ${ROBOT_OUTPUT_DIR}/helm-acceptance-temp-bin.XXXXXX)
trap "rm -rf ${TMP_HELM_DIR}" EXIT

mkdir -p $TMP_HELM_DIR
HELM_DIR=$(dirname $(which helm))
cp $HELM_DIR/helm $TMP_HELM_DIR/helm

# Make 'helm' unavailable to make sure it can't be called direactly
# by the dynamic completion code, which should instead use the helm
# as called in the completion calls that follow.
alias helm=echo

# Testing with shell aliases is only applicable to bash.
# Zsh replaces the alias before calling the completion function,
# so it does not make sense to try zsh completion with an alias.
if [ "$SHELL_TYPE" = bash ]; then

    # Create aliases to helm
    # This alias will be created after the variable is expanded
    alias helmAlias="${TMP_HELM_DIR}/helm"
    # This alias will be created without expanding the variable (because of single quotes)
    alias helmAliasWithVar='${TMP_HELM_DIR}/helm'

    # Hook these new aliases to the helm completion function.
    complete -o default -F $(_completionTests_findCompletionFunction helm) helmAlias
    complete -o default -F $(_completionTests_findCompletionFunction helm) helmAliasWithVar

    # Completion with normal alias
    _completionTests_verifyCompletion "helmAlias lis" "list"
    _completionTests_verifyCompletion "helmAlias completion z" "zsh"
    _completionTests_verifyCompletion "helmAlias --kubecon" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "helmAlias get hooks --kubec" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "helmAlias repo remove zztest" "zztest1 zztest2"
    _completionTests_verifyCompletion "helmAlias plugin update pus" "push push-artifactory"
    _completionTests_verifyCompletion "helmAlias upgrade --kube-context d" "dev1 dev2"
    if [ ! -z ${ROBOT_HELM_V3} ]; then
        _completionTests_verifyCompletion "helmAlias --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
    fi

    # Completion with alias that contains a variable
    _completionTests_verifyCompletion "helmAliasWithVar lis" "list"
    _completionTests_verifyCompletion "helmAliasWithVar completion z" "zsh"
    _completionTests_verifyCompletion "helmAliasWithVar --kubecon" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "helmAliasWithVar get hooks --kubec" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "helmAliasWithVar repo remove zztest" "zztest1 zztest2"
    _completionTests_verifyCompletion "helmAliasWithVar plugin update pus" "push push-artifactory"
    _completionTests_verifyCompletion "helmAliasWithVar upgrade --kube-context d" "dev1 dev2"
    if [ ! -z ${ROBOT_HELM_V3} ]; then
        _completionTests_verifyCompletion "helmAliasWithVar --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
    fi
fi

# Completion with absolute path
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm lis" "list"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm completion z" "zsh"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm upgrade --kube-context d" "dev1 dev2"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "$TMP_HELM_DIR/helm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
fi
if [ "$SHELL_TYPE" = bash ]; then
    _completionTests_verifyCompletion "$TMP_HELM_DIR/helm --kubecon" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "$TMP_HELM_DIR/helm get hooks --kubec" "--kubeconfig= --kubeconfig"
else
    _completionTests_verifyCompletion "$TMP_HELM_DIR/helm --kubecon" "--kubeconfig --kubeconfig --kubeconfig"
    _completionTests_verifyCompletion "$TMP_HELM_DIR/helm get hooks --kubec" "--kubeconfig --kubeconfig --kubeconfig"
fi

# Completion with relative path
cd $TMP_HELM_DIR
_completionTests_verifyCompletion "./helm lis" "list"
_completionTests_verifyCompletion "./helm completion z" "zsh"
_completionTests_verifyCompletion "./helm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "./helm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "./helm upgrade --kube-context d" "dev1 dev2"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "./helm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
fi
if [ "$SHELL_TYPE" = bash ]; then
    _completionTests_verifyCompletion "./helm --kubecon" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "./helm get hooks --kubec" "--kubeconfig= --kubeconfig"
else
    _completionTests_verifyCompletion "./helm --kubecon" "--kubeconfig --kubeconfig --kubeconfig"
    _completionTests_verifyCompletion "./helm get hooks --kubec" "--kubeconfig --kubeconfig --kubeconfig"
fi
cd - >/dev/null

# Completion with a different name for helm
mv $TMP_HELM_DIR/helm $TMP_HELM_DIR/myhelm

# Generating the completion script using the new binary name
# should make completion work for that binary name
source /dev/stdin <<- EOF
   $(${TMP_HELM_DIR}/myhelm completion $SHELL_TYPE)
EOF
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm lis" "list"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm completion z" "zsh"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm upgrade --kube-context d" "dev1 dev2"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
fi
if [ "$SHELL_TYPE" = bash ]; then
    _completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm --kubecon" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm get hooks --kubec" "--kubeconfig= --kubeconfig"
else
    _completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm --kubecon" "--kubeconfig --kubeconfig --kubeconfig"
    _completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm get hooks --kubec" "--kubeconfig --kubeconfig --kubeconfig"
fi

# Completion with a different name for helm that is on PATH
mv $TMP_HELM_DIR/myhelm $HELM_DIR/myhelm
_completionTests_verifyCompletion "myhelm lis" "list"
_completionTests_verifyCompletion "myhelm completion z" "zsh"
_completionTests_verifyCompletion "myhelm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "myhelm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "myhelm upgrade --kube-context d" "dev1 dev2"
if [ ! -z ${ROBOT_HELM_V3} ]; then
    _completionTests_verifyCompletion "myhelm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
fi
if [ "$SHELL_TYPE" = bash ]; then
    _completionTests_verifyCompletion "myhelm --kubecon" "--kubeconfig= --kubeconfig"
    _completionTests_verifyCompletion "myhelm get hooks --kubec" "--kubeconfig= --kubeconfig"
else
    _completionTests_verifyCompletion "myhelm --kubecon" "--kubeconfig --kubeconfig --kubeconfig"
    _completionTests_verifyCompletion "myhelm get hooks --kubec" "--kubeconfig --kubeconfig --kubeconfig"
fi
unalias helm

# This must be the last call.  It allows to exit with an exit code
# that reflects the final status of all the tests.
_completionTests_exit

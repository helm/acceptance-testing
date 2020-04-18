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

#####################
# Static completions
#####################

# Completion of flags
_completionTests_verifyCompletion "helm --kube-con" "--kube-context= --kube-context"
_completionTests_verifyCompletion "helm --kubecon" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "helm --v" "--v= --vmodule= --v --vmodule"
_completionTests_verifyCompletion "helm --name" "--namespace= --namespace"
_completionTests_verifyCompletion "helm --s" "--skip-headers --skip-log-headers --stderrthreshold --stderrthreshold="
_completionTests_verifyCompletion "helm show --s" "--skip-headers --skip-log-headers --stderrthreshold --stderrthreshold="
_completionTests_verifyCompletion "helm get hooks --kubec" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "helm get --name" "--namespace= --namespace"

#####################
# Dynamic completions
#####################

# For the global --kube-context flag
_completionTests_verifyCompletion "helm --kube-context=" "dev1 dev2 accept prod"

# Make sure completion works as expected when there are no repositories configured
XDG_CONFIG_HOME='/invalid/path' _completionTests_verifyCompletion "helm repo remove " ""
# Make sure completion works as expected when there are no plugins
XDG_DATA_HOME='/invalid/path' _completionTests_verifyCompletion "helm plugin uninstall " ""

# Dynamic completion for plugins
_completionTests_verifyCompletion "helm 2to3 move config g" "gryffindor"
_completionTests_verifyCompletion "helm 2to3 convert -s flag d" "dobby draco"
_completionTests_verifyCompletion "helm push-artifactory move config g" "gryffindor"
_completionTests_verifyCompletion "helm push-artifactory convert -s flag d" "dobby draco"

# Now requires a real cluster
# _completionTests_verifyCompletion "helm --namespace=" "casterly-rock white-harbor winterfell"
# _completionTests_verifyCompletion "helm --namespace=w" "white-harbor winterfell"
# _completionTests_verifyCompletion "helm upgrade --namespace=w" "white-harbor winterfell"
# _completionTests_verifyCompletion "helm upgrade --namespace=" "casterly-rock white-harbor winterfell"
# _completionTests_verifyCompletion "helm -n=" "casterly-rock white-harbor winterfell"
# _completionTests_verifyCompletion "helm -n=w" "white-harbor winterfell"
# _completionTests_verifyCompletion "helm upgrade -n=w" "white-harbor winterfell"
# _completionTests_verifyCompletion "helm upgrade -n=" "casterly-rock white-harbor winterfell"

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

# Make 'helm' unavailable to make sure it can't be called directly
# by the dynamic completion code, which should instead use the helm
# as called in the completion calls that follow.
alias helm=echo

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
#_completionTests_verifyCompletion "helmAlias --kube-context=mycontext --namespace " "braavos old-valyria yunkai"

# Completion with alias that contains a variable
_completionTests_verifyCompletion "helmAliasWithVar lis" "list"
_completionTests_verifyCompletion "helmAliasWithVar completion z" "zsh"
_completionTests_verifyCompletion "helmAliasWithVar --kubecon" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "helmAliasWithVar get hooks --kubec" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "helmAliasWithVar repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "helmAliasWithVar plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "helmAliasWithVar upgrade --kube-context d" "dev1 dev2"
#_completionTests_verifyCompletion "helmAliasWithVar --kube-context=mycontext --namespace " "braavos old-valyria yunkai"

# Completion with absolute path
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm lis" "list"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm completion z" "zsh"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm upgrade --kube-context d" "dev1 dev2"
#_completionTests_verifyCompletion "$TMP_HELM_DIR/helm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm --kubecon" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "$TMP_HELM_DIR/helm get hooks --kubec" "--kubeconfig= --kubeconfig"

# Completion with relative path
cd $TMP_HELM_DIR
_completionTests_verifyCompletion "./helm lis" "list"
_completionTests_verifyCompletion "./helm completion z" "zsh"
_completionTests_verifyCompletion "./helm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "./helm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "./helm upgrade --kube-context d" "dev1 dev2"
#_completionTests_verifyCompletion "./helm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
_completionTests_verifyCompletion "./helm --kubecon" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "./helm get hooks --kubec" "--kubeconfig= --kubeconfig"

cd - >/dev/null

# Completion with a different name for helm
mv $TMP_HELM_DIR/helm $TMP_HELM_DIR/myhelm

# Generating the completion script using the new binary name
# should make completion work for that binary name
source /dev/stdin <<- EOF
   $(${TMP_HELM_DIR}/myhelm completion bash)
EOF
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm lis" "list"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm completion z" "zsh"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm upgrade --kube-context d" "dev1 dev2"
#_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm --kubecon" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "$TMP_HELM_DIR/myhelm get hooks --kubec" "--kubeconfig= --kubeconfig"

# Completion with a different name for helm that is on PATH
mv $TMP_HELM_DIR/myhelm $HELM_DIR/myhelm
_completionTests_verifyCompletion "myhelm lis" "list"
_completionTests_verifyCompletion "myhelm completion z" "zsh"
_completionTests_verifyCompletion "myhelm repo remove zztest" "zztest1 zztest2"
_completionTests_verifyCompletion "myhelm plugin update pus" "push push-artifactory"
_completionTests_verifyCompletion "myhelm upgrade --kube-context d" "dev1 dev2"
#_completionTests_verifyCompletion "myhelm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"
_completionTests_verifyCompletion "myhelm --kubecon" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "myhelm get hooks --kubec" "--kubeconfig= --kubeconfig"

unalias helm

# This must be the last call.  It allows to exit with an exit code
# that reflects the final status of all the tests.
_completionTests_exit

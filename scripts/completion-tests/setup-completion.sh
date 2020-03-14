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

# This script tests different scenarios of completion.  The tests can be
# run by sourcing this file from a bash shell or a zsh shell.

export SHELL_TYPE=$1
case "$SHELL_TYPE" in
bash|zsh|fish)
    ;;
"")
    echo "Missing parameter for shell to test"
    exit 1
    ;;
*)
    echo "Invalid shell to test: $SHELL_TYPE"
    exit 1
    ;;
esac

export PATH=${COMP_DIR}/bin:$PATH

# Use the memory driver with pre-defined releases to easily
# test release name completion
export HELM_DRIVER=memory
export HELM_MEMORY_DRIVER_DATA=${COMP_DIR}/releases.yaml

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

##############################################################
# REPOS SETUP
##############################################################

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
# Fetch the details of the stable repo
helm repo update

##############################################################
# PLUGINS SETUP
##############################################################

# Setup some plugins to allow testing completion of the helm plugin command
# We inject the content of different plugin.yaml files directly to avoid having
# to install a real plugin which can take a long time.

###########
# Plugin 1
###########
PLUGIN_DIR=${PLUGIN_ROOT}/helm-2to3
mkdir -p ${PLUGIN_DIR}
# The plugin file
cat > ${PLUGIN_DIR}/plugin.yaml << EOF
name: "2to3"
version: "2.5.1+2"
description: "Migrate from helm v2 to helm v3"
EOF

# The plugin's static completion file
cat > ${PLUGIN_DIR}/completion.yaml << EOF
commands:
- name: cleanup
  flags:
  - r
  - label
  - cleanup
  - s
  - storage
- name: convert
  flags:
  - l
  - label
  - s
  - storage
  - t
- name: move
  commands:
  - name: config
    flags:
    - dry-run
EOF

# The plugin's dynamic completion file
cat > ${PLUGIN_DIR}/plugin.complete << EOF
#!/usr/bin/env sh

if [ "\$2" = "config" ]; then
    echo case-config
    echo gryffindor
    echo slytherin
    echo ravenclaw
    echo hufflepuff
    echo :0
    exit
fi

if [ "\$HELM_NAMESPACE" != "default" ]; then
    echo case-ns
    # Check the namespace flag is not passed
    echo \$1
    # Check plugin variables are set
    echo \$HELM_NAMESPACE
    echo :4
    exit
fi

if [ "\$2" = -s ]; then
    echo case-flag
    echo lucius
    echo draco
    echo dobby
    echo :4
    exit
fi

# Check missing directive
echo hermione
echo harry
echo ron
EOF
chmod u+x ${PLUGIN_DIR}/plugin.complete

###########
# Plugin 2
###########
PLUGIN_DIR=${PLUGIN_ROOT}/helm-push
mkdir -p ${PLUGIN_DIR}
# The plugin file
cat > ${PLUGIN_DIR}/plugin.yaml << EOF
name: "push"
version: "0.7.1"
description: "Push chart package to ChartMuseum"
EOF

# A plugin's static completion file without a dynamic completion file
cat > ${PLUGIN_DIR}/completion.yaml << EOF
commands:
- name: cleanup
  flags:
  - r
  - label
  - cleanup
  - s
  - storage
- name: convert
  flags:
  - l
  - label
  - s
  - storage
  - t
- name: move
  commands:
  - name: config
    flags:
    - dry-run
EOF

###########
# Plugin 3
###########
PLUGIN_DIR=${PLUGIN_ROOT}/helm-push-artifactory
mkdir -p ${PLUGIN_DIR}
# The plugin file
cat > ${PLUGIN_DIR}/plugin.yaml << EOF
name: "push-artifactory"
version: "0.3.0"
description: "Push helm charts to artifactory"
EOF

# A plugin's dynamic completion file without a static completion file
cat > ${PLUGIN_DIR}/plugin.complete << EOF
#!/usr/bin/env sh

if [ "\$2" = "config" ]; then
    echo case-config
    echo gryffindor
    echo slytherin
    echo ravenclaw
    echo hufflepuff
    echo :0
    exit
fi

if [ "\$HELM_NAMESPACE" != "default" ]; then
    echo case-ns
    # Check the namespace flag is not passed
    echo \$1
    # Check plugin variables are set
    echo \$HELM_NAMESPACE
    echo :4
    exit
fi

if [ "\$2" = -s ]; then
    echo case-flag
    echo lucius
    echo draco
    echo dobby
    echo :4
    exit
fi

# Check missing directive
echo hermione
echo harry
echo ron
EOF
chmod u+x ${PLUGIN_DIR}/plugin.complete

helm plugin list

##############################################################
# CONTEXTS SETUP
##############################################################

# config file stubs
cat > ${COMP_DIR}/config.dev1 << EOF
kind: Config
apiVersion: v1
contexts:
- context:
  name: dev1
current-context: dev1
EOF
cat > ${COMP_DIR}/config.dev2 << EOF
kind: Config
apiVersion: v1
contexts:
- context:
  name: dev2
current-context: dev2
EOF
cat > ${COMP_DIR}/config.accept << EOF
kind: Config
apiVersion: v1
contexts:
- context:
  name: accept
current-context: accept
EOF
cat > ${COMP_DIR}/config.prod << EOF
kind: Config
apiVersion: v1
contexts:
- context:
  name: prod
current-context: prod
EOF
export KUBECONFIG=${COMP_DIR}/config.dev1:${COMP_DIR}/config.dev2:${COMP_DIR}/config.accept:${COMP_DIR}/config.prod

export allHelmCommands="completion create dependency env 2to3 get history install lint list package plugin pull push push-artifactory repo rollback search show status template test uninstall upgrade verify version"
case "$SHELL_TYPE" in
bash|fish)
    export allHelmGlobalFlags="--add-dir-header --alsologtostderr --debug --kube-apiserver --kube-apiserver= --kube-context --kube-context= --kube-token --kube-token= --kubeconfig --kubeconfig= --log-backtrace-at --log-backtrace-at= --log-dir --log-dir= --log-file --log-file-max-size --log-file-max-size= --log-file= --logtostderr --namespace --namespace= --registry-config --registry-config= --repository-cache --repository-cache= --repository-config --repository-config= --skip-headers --skip-log-headers --stderrthreshold --stderrthreshold= --v --v= --vmodule --vmodule= -n -v"
    export allHelmLongFlags="--add-dir-header --alsologtostderr --debug --kube-apiserver --kube-apiserver= --kube-context --kube-context= --kube-token --kube-token= --kubeconfig --kubeconfig= --log-backtrace-at --log-backtrace-at= --log-dir --log-dir= --log-file --log-file-max-size --log-file-max-size= --log-file= --logtostderr --namespace --namespace= --registry-config --registry-config= --repository-cache --repository-cache= --repository-config --repository-config= --skip-headers --skip-log-headers --stderrthreshold --stderrthreshold= --v --v= --vmodule --vmodule="
    ;;
zsh)
    export allHelmGlobalFlags="--add-dir-header --alsologtostderr --debug --kube-apiserver --kube-apiserver --kube-apiserver --kube-context --kube-context --kube-context --kube-token --kube-token --kube-token --kubeconfig --kubeconfig --kubeconfig --log-backtrace-at --log-backtrace-at --log-backtrace-at --log-dir --log-dir --log-dir --log-file --log-file --log-file --log-file-max-size --log-file-max-size --log-file-max-size --logtostderr --namespace --namespace --namespace --registry-config --registry-config --registry-config --repository-cache --repository-cache --repository-cache --repository-config --repository-config --repository-config --skip-headers --skip-log-headers --stderrthreshold --stderrthreshold --stderrthreshold --v --v --v --vmodule --vmodule --vmodule -n -v"
    export allHelmLongFlags="--add-dir-header --alsologtostderr --debug --kube-apiserver --kube-apiserver --kube-apiserver --kube-context --kube-context --kube-context --kube-token --kube-token --kube-token --kubeconfig --kubeconfig --kubeconfig --log-backtrace-at --log-backtrace-at --log-backtrace-at --log-dir --log-dir --log-dir --log-file --log-file --log-file --log-file-max-size --log-file-max-size --log-file-max-size --logtostderr --namespace --namespace --namespace --registry-config --registry-config --registry-config --repository-cache --repository-cache --repository-cache --repository-config --repository-config --repository-config --skip-headers --skip-log-headers --stderrthreshold --stderrthreshold --stderrthreshold --v --v --v --vmodule --vmodule --vmodule"
    ;;
esac

case "$SHELL_TYPE" in
bash)
    bash -c "source ${COMP_DIR}/run-completionTests.bash"
    ;;
zsh)
    zsh -c "source ${COMP_DIR}/run-completionTests.zsh"
    ;;
fish)
    fish -c "source ${COMP_DIR}/run-completionTests.fish"
    ;;
esac

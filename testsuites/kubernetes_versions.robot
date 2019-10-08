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

*** Settings ***
Documentation     Verify Helm functionality on multiple Kubernetes versions.
...
...               Fresh new kind-based clusters will be created for each
...               of the Kubernetes versions being tested. An existing
...               kind cluster can be used by specifying it in an env var
...               representing the version, for example:
...
...                  export KIND_CLUSTER_1_16_1="helm-ac-keepalive-1.16.1"
...                  export KIND_CLUSTER_1_15_4="helm-ac-keepalive-1.15.4"
...                  export KIND_CLUSTER_1_14_7="helm-ac-keepalive-1.14.7"
...
Library           String
Library           OperatingSystem
Library           ../lib/Kind.py
Library           ../lib/Kubectl.py
Library           ../lib/Helm.py
Library           ../lib/Sh.py
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown

*** Test Cases ***
#Helm works with Kubernetes 1.16.1
#    Test Helm on Kubernetes version   1.16.1

Helm works with Kubernetes 1.15.3
    Test Helm on Kubernetes version   1.15.3

Helm works with Kubernetes 1.14.6
    Test Helm on Kubernetes version   1.14.6

*** Keyword ***
Test Helm on Kubernetes version
    Require cluster  True

    ${helm_version} =  Get Environment Variable  ROBOT_HELM_V3  "v2"
    Pass Execution If  ${helm_version} == 'v2'  Helm v2 not supported. Skipping test.

    [Arguments]    ${kube_version}
    Create test cluster with kube version    ${kube_version}

    # Add new test cases here
    Verify --wait flag works as expected

    Kind.Delete test cluster

Create test cluster with kube version
    [Arguments]    ${kube_version}
    Kind.Create test cluster with Kubernetes version  ${kube_version}
    Kind.Wait for cluster
    Should pass  kubectl get nodes
    Should pass  kubectl get pods --namespace=kube-system

Verify --wait flag works as expected
    # Install nginx chart in a good state, using --wait flag
    Sh.Run  helm delete wait-flag-good
    Helm.Install test chart    wait-flag-good    nginx   --wait --timeout=60s
    Helm.Return code should be  0

    # Make sure everything is up-and-running
    Sh.Run  kubectl get pods --namespace=default
    Sh.Run  kubectl get services --namespace=default
    Sh.Run  kubectl get pvc --namespace=default

    Kubectl.Service has IP  default    wait-flag-good-nginx
    Kubectl.Return code should be   0

    Kubectl.Persistent volume claim is bound    default    wait-flag-good-nginx
    Kubectl.Return code should be   0

    Kubectl.Pods with prefix are running    default    wait-flag-good-nginx-ext-    3
    Kubectl.Return code should be   0
    Kubectl.Pods with prefix are running    default    wait-flag-good-nginx-fluentd-es-    1
    Kubectl.Return code should be   0
    Kubectl.Pods with prefix are running    default    wait-flag-good-nginx-v1-    3
    Kubectl.Return code should be   0
    Kubectl.Pods with prefix are running    default    wait-flag-good-nginx-v1beta1-    3
    Kubectl.Return code should be   0
    Kubectl.Pods with prefix are running    default    wait-flag-good-nginx-v1beta2-    3
    Kubectl.Return code should be   0
    Kubectl.Pods with prefix are running    default    wait-flag-good-nginx-web-   3
    Kubectl.Return code should be   0

    # Delete good release
    Should pass  helm delete wait-flag-good

    # Install nginx chart in a bad state, using --wait flag
    Sh.Run  helm delete wait-flag-bad
    Helm.Install test chart    wait-flag-bad   nginx   --wait --timeout=60s --set breakme=true

    # Install should return non-zero, as things fail to come up
    Helm.Return code should not be  0

    # Make sure things are NOT up-and-running
    Sh.Run  kubectl get pods --namespace=default
    Sh.Run  kubectl get services --namespace=default
    Sh.Run  kubectl get pvc --namespace=default

    Kubectl.Persistent volume claim is bound    default    wait-flag-bad-nginx
    Kubectl.Return code should not be   0

    Kubectl.Pods with prefix are running    default    wait-flag-bad-nginx-ext-    3
    Kubectl.Return code should not be   0
    Kubectl.Pods with prefix are running    default    wait-flag-bad-nginx-fluentd-es-    1
    Kubectl.Return code should not be   0
    Kubectl.Pods with prefix are running    default    wait-flag-bad-nginx-v1-    3
    Kubectl.Return code should not be   0
    Kubectl.Pods with prefix are running    default    wait-flag-bad-nginx-v1beta1-    3
    Kubectl.Return code should not be   0
    Kubectl.Pods with prefix are running    default    wait-flag-bad-nginx-v1beta2-    3
    Kubectl.Return code should not be   0
    Kubectl.Pods with prefix are running    default    wait-flag-bad-nginx-web-   3
    Kubectl.Return code should not be   0

    # Delete bad release
    Should pass  helm delete wait-flag-bad

Suite Setup
    Kind.Cleanup all test clusters

Suite Teardown
    Kind.Cleanup all test clusters

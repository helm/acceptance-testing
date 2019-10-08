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
Documentation     Verify helm repo commands work as expected.
...
Library           OperatingSystem
Library           ../lib/Sh.py

*** Test Cases ***
No repos provisioned yet
    Check helm version
    Should fail  helm repo list
    Output contains  Error: no repositories

Add a first valid repo
    Check helm version
    Should pass  helm repo add gitlab https://charts.gitlab.io
    Output contains  "gitlab" has been added to your repositories

Add invalid repo without protocol
    Check helm version
    Should fail  helm repo add invalid notAValidURL
    Output contains  Error: could not find protocol handler

Add invalid repo with protocol
    Check helm version
    Should fail  helm repo add invalid https://example.com
    Output contains  Error: looks like "https://example.com" is not a valid chart repository or cannot be reached

Add a second valid repo
    Check helm version
    Should pass  helm repo add jfrog https://charts.jfrog.io
    Output contains  "jfrog" has been added to your repositories

Check output of repo list
    Check helm version
    Should pass  helm repo list
    Output contains  gitlab
    Output contains  https://charts.gitlab.io
    Output contains  jfrog
    Output contains  https://charts.jfrog.io
    Output does not contain  invalid

Make sure both repos get updated
    Check helm version
    Should pass  helm repo update
    Output contains  Successfully got an update from the "gitlab" chart repository
    Output contains  Successfully got an update from the "jfrog" chart repository
    Output contains  Update Complete. ⎈ Happy Helming!⎈

Try to remove nonexistent repo
    Check helm version
    Should fail  helm repo remove badname
    Output contains  Error: no repo named "badname" found

Remove a repo
    Check helm version
    Should pass  helm repo remove gitlab
    Output contains  "gitlab" has been removed from your repositories

Make sure repo update will only update the remaining repo
    Check helm version
    Should pass  helm repo update
    Output contains  Successfully got an update from the "jfrog" chart repository
    Output contains  Update Complete. ⎈ Happy Helming!⎈

Try removing an already removed repo
    Check helm version
    Should fail  helm repo remove gitlab
    Output contains  Error: no repo named "gitlab" found

Remove last repo
    Check helm version
    Should pass  helm repo remove jfrog
    Output contains  "jfrog" has been removed from your repositories

Check there are no more repos
    Check helm version
    Should fail  helm repo list
    Output contains  Error: no repositories to show

Make sure repo update now fails, with a proper message
    Check helm version
    Should fail  helm repo update
    Output contains  Error: no repositories found. You must add one before updating

# "helm repo index" should also be tested

*** Keyword ***
Check helm version
    ${helm_version} =  Get Environment Variable  ROBOT_HELM_V3  "v2"
    Pass Execution If  ${helm_version} == 'v2'  Helm v2 not supported. Skipping test.

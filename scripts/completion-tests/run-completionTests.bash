#!zsh
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
#

echo "===================================================="
echo "Running completions tests on $(uname) with bash $BASH_VERSION"
echo "===================================================="

# Enable aliases to work even though we are in a script (non-interactive shell).
# This allows to test completion with aliases.
# Only needed for bash, zsh does this automatically.
shopt -s expand_aliases

bashCompletionScript="/usr/share/bash-completion/bash_completion"
if [ $(uname) = "Darwin" ]; then
   bashCompletionScript="/usr/local/etc/bash_completion"
fi

source ${bashCompletionScript}

source ${COMP_DIR}/run-completionTests-common.sh
source ${COMP_DIR}/completionTests-common.sh
source ${COMP_DIR}/completionTests.bash
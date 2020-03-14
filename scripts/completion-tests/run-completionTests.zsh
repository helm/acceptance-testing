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
echo "Running completions tests on $(uname) with zsh $ZSH_VERSION"
echo "===================================================="
autoload -Uz compinit
compinit
# When zsh calls real completion, it sets some options and emulates sh.
# We need to do the same.
emulate -L sh
setopt kshglob noshglob braceexpand

source ${COMP_DIR}/run-completionTests-common.sh
source ${COMP_DIR}/completionTests-common.sh
source ${COMP_DIR}/completionTests.zsh
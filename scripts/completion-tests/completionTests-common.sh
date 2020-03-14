#!sh
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

#############################################################################
# This file holds all tests that apply to all shells (bash, zsh, fish)
# It cannot use any if statements since their syntax is not portable
# between shells.
#
# For tests that are specific to a shell, use the proper specific file.
#############################################################################


#####################
# Static completions
#####################

# Basic first level commands (static completion)
_completionTests_verifyCompletion "helm " "$allHelmCommands"
_completionTests_verifyCompletion "helm help " "$allHelmCommands"
_completionTests_verifyCompletion "helm sho" "show"
_completionTests_verifyCompletion "helm help sho" "show"
_completionTests_verifyCompletion "helm --debug " "$allHelmCommands"
_completionTests_verifyCompletion "helm --debug sho" "show"
_completionTests_verifyCompletion "helm -n ns " "$allHelmCommands"
_completionTests_verifyCompletion "helm -n ns sho" "show"
_completionTests_verifyCompletion "helm --namespace ns " "$allHelmCommands"
_completionTests_verifyCompletion "helm --namespace ns sho" "show"
_completionTests_verifyCompletion "helm stat" "status"
_completionTests_verifyCompletion "helm status" "status"
_completionTests_verifyCompletion "helm lis" "list"
_completionTests_verifyCompletion "helm r" "repo rollback"
_completionTests_verifyCompletion "helm re" "repo"

# Basic second level commands (static completion)
_completionTests_verifyCompletion "helm get " "all hooks manifest notes values"
_completionTests_verifyCompletion "helm get h" "hooks"
_completionTests_verifyCompletion "helm completion " "bash zsh fish"
_completionTests_verifyCompletion "helm completion z" "zsh"
_completionTests_verifyCompletion "helm plugin " "install list uninstall update"
_completionTests_verifyCompletion "helm plugin u" "uninstall update"
_completionTests_verifyCompletion "helm --debug plugin " "install list uninstall update"
_completionTests_verifyCompletion "helm --debug plugin u" "uninstall update"
_completionTests_verifyCompletion "helm -n ns plugin " "install list uninstall update"
_completionTests_verifyCompletion "helm -n ns plugin u" "uninstall update"
_completionTests_verifyCompletion "helm --namespace ns plugin " "install list uninstall update"
_completionTests_verifyCompletion "helm --namespace ns plugin u" "uninstall update"
_completionTests_verifyCompletion "helm plugin --debug " "install list uninstall update"
_completionTests_verifyCompletion "helm plugin --debug u" "uninstall update"
_completionTests_verifyCompletion "helm plugin -n ns " "install list uninstall update"
_completionTests_verifyCompletion "helm plugin -n ns u" "uninstall update"
_completionTests_verifyCompletion "helm plugin --namespace ns " "install list uninstall update"
_completionTests_verifyCompletion "helm plugin --namespace ns u" "uninstall update"

# With validArgs
_completionTests_verifyCompletion "helm completion " "bash zsh fish"
_completionTests_verifyCompletion "helm completion z" "zsh"
_completionTests_verifyCompletion "helm --debug completion " "bash zsh fish"
_completionTests_verifyCompletion "helm --debug completion z" "zsh"
_completionTests_verifyCompletion "helm -n ns completion " "bash zsh fish"
_completionTests_verifyCompletion "helm -n ns completion z" "zsh"
_completionTests_verifyCompletion "helm --namespace ns completion " "bash zsh fish"
_completionTests_verifyCompletion "helm --namespace ns completion z" "zsh"

# Completion of flags
_completionTests_verifyCompletion "helm -v" "-v"
_completionTests_verifyCompletion "helm -" "$allHelmGlobalFlags"
_completionTests_verifyCompletion "helm --" "$allHelmLongFlags"
_completionTests_verifyCompletion "helm show -" "$allHelmGlobalFlags"
_completionTests_verifyCompletion "helm show --" "$allHelmLongFlags"
_completionTests_verifyCompletion "helm -n" "-n"
_completionTests_verifyCompletion "helm show -n" "-n"

# Completion of commands while using flags
_completionTests_verifyCompletion "helm --kube-context prod sta" "status"
_completionTests_verifyCompletion "helm --kubeconfig=$COMP_DIR/config.dev1 lis" "list"
_completionTests_verifyCompletion "helm --namespace mynamespace get h" "hooks"
_completionTests_verifyCompletion "helm -v 3 get " "all hooks manifest notes values"

# Cobra command aliases are purposefully not completed
_completionTests_verifyCompletion "helm ls" ""
_completionTests_verifyCompletion "helm dependenci" ""

# Static completion for plugins
_completionTests_verifyCompletion "helm 2to3 " "cleanup convert move"
_completionTests_verifyCompletion "helm 2to3 c" "cleanup convert"
_completionTests_verifyCompletion "helm 2to3 move " "config"
_completionTests_verifyCompletion "helm push " "cleanup convert move"
_completionTests_verifyCompletion "helm push c" "cleanup convert"
_completionTests_verifyCompletion "helm push move " "config"

_completionTests_verifyCompletion "helm 2to3 cleanup -" "$allHelmGlobalFlags -r -s --label --cleanup --storage"
_completionTests_verifyCompletion "helm push cleanup -" "$allHelmGlobalFlags -r -s --label --cleanup --storage"
# For plugin completion, when there are more short flags than long flags, a long flag is created for the extra short flags
# So here we expect the extra --t
_completionTests_verifyCompletion "helm 2to3 convert -" "$allHelmGlobalFlags -l -s -t --t --label --storage"
_completionTests_verifyCompletion "helm 2to3 move config --" "$allHelmLongFlags --dry-run"
_completionTests_verifyCompletion "helm push convert -" "$allHelmGlobalFlags -l -s -t --t --label --storage"
_completionTests_verifyCompletion "helm push move config --" "$allHelmLongFlags --dry-run"

#####################
# Dynamic completions
#####################

# For release name completion
_completionTests_verifyCompletion "helm status " "athos porthos aramis"
_completionTests_verifyCompletion "helm history a" "athos aramis"
_completionTests_verifyCompletion "helm uninstall a" "athos aramis"
_completionTests_verifyCompletion "helm upgrade a" "athos aramis"
_completionTests_verifyCompletion "helm get manifest -n default " "athos porthos aramis"
_completionTests_verifyCompletion "helm --namespace gascony get manifest " "dartagnan"
_completionTests_verifyCompletion "helm --namespace gascony test d" "dartagnan"
_completionTests_verifyCompletion "helm rollback d" ""

# For the repo command
_completionTests_verifyCompletion "helm repo remove " "stable zztest1 zztest2"
_completionTests_verifyCompletion "helm repo remove zztest" "zztest1 zztest2"

# For the plugin command
_completionTests_verifyCompletion "helm plugin uninstall " "2to3 push push-artifactory"
_completionTests_verifyCompletion "helm plugin uninstall pu" "push push-artifactory"
_completionTests_verifyCompletion "helm plugin update " "2to3 push push-artifactory"
_completionTests_verifyCompletion "helm plugin update pus" "push push-artifactory"

# For the global --kube-context flag
_completionTests_verifyCompletion "helm --kube-context " "dev1 dev2 accept prod"
_completionTests_verifyCompletion "helm upgrade --kube-context " "dev1 dev2 accept prod"
_completionTests_verifyCompletion "helm upgrade --kube-context d" "dev1 dev2"

# Now requires a real cluster
# # For the global --namespace flag
# _completionTests_verifyCompletion "helm --namespace " "casterly-rock white-harbor winterfell"
# _completionTests_verifyCompletion "helm --namespace w" "white-harbor winterfell"
# _completionTests_verifyCompletion "helm upgrade --namespace " "casterly-rock white-harbor winterfell"
# _completionTests_verifyCompletion "helm -n " "casterly-rock white-harbor winterfell"
# _completionTests_verifyCompletion "helm -n w" "white-harbor winterfell"
# _completionTests_verifyCompletion "helm upgrade -n " "casterly-rock white-harbor winterfell"
# # With override flags
# _completionTests_verifyCompletion "helm --kubeconfig myconfig --namespace " "meereen myr volantis"
# _completionTests_verifyCompletion "helm --kubeconfig=myconfig --namespace " "meereen myr volantis"
# _completionTests_verifyCompletion "helm --kube-context mycontext --namespace " "braavos old-valyria yunkai"
# _completionTests_verifyCompletion "helm --kube-context=mycontext --namespace " "braavos old-valyria yunkai"

# For the --output flag that applies to multiple commands
_completionTests_verifyCompletion "helm repo list --output " "json table yaml"
_completionTests_verifyCompletion "helm install --output " "json table yaml"
_completionTests_verifyCompletion "helm history -o " "json table yaml"
_completionTests_verifyCompletion "helm list -o " "json table yaml"

# For completing specification of charts
touch zztest2file files

_completionTests_verifyCompletion "helm show values " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
_completionTests_verifyCompletion "helm show values ht" "http:// https://"
_completionTests_verifyCompletion "helm show values zz" "zztest1/ zztest2/ zztest2file"
_completionTests_verifyCompletion "helm show values zztest2" "zztest2/ zztest2file"
_completionTests_verifyCompletion "helm show values zztest2f" ""
_completionTests_verifyCompletion "helm show values stable/yyy" ""
_completionTests_verifyCompletion "helm show values stable/z" "stable/zeppelin stable/zetcd"
_completionTests_verifyCompletion "helm show values fil" "file:// files"

_completionTests_verifyCompletion "helm show chart zz" "zztest1/ zztest2/ zztest2file"
_completionTests_verifyCompletion "helm show readme zz" "zztest1/ zztest2/ zztest2file"
_completionTests_verifyCompletion "helm show values zz" "zztest1/ zztest2/ zztest2file"

_completionTests_verifyCompletion "helm pull " "zztest1/ zztest2/ stable/ file:// http:// https://"
_completionTests_verifyCompletion "helm pull zz" "zztest1/ zztest2/"

_completionTests_verifyCompletion "helm install name " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
_completionTests_verifyCompletion "helm install name zz" "zztest1/ zztest2/ zztest2file"
_completionTests_verifyCompletion "helm install name stable/z" "stable/zeppelin stable/zetcd"

_completionTests_verifyCompletion "helm template name " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
_completionTests_verifyCompletion "helm template name zz" "zztest1/ zztest2/ zztest2file"
_completionTests_verifyCompletion "helm template name stable/z" "stable/zeppelin stable/zetcd"

_completionTests_verifyCompletion "helm upgrade release " "./ / zztest1/ zztest2/ stable/ file:// http:// https://"
_completionTests_verifyCompletion "helm upgrade release zz" "zztest1/ zztest2/ zztest2file"
_completionTests_verifyCompletion "helm upgrade release stable/z" "stable/zeppelin stable/zetcd"

_completionTests_verifyCompletion "helm show values stab" "stable/ stable/."

rm zztest2file files

# Dynamic completion for plugins
_completionTests_verifyCompletion "helm 2to3 -n dumbledore convert " "case-ns convert dumbledore"
_completionTests_verifyCompletion "helm 2to3 convert " "hermione harry ron"
_completionTests_verifyCompletion "helm push-artifactory -n dumbledore convert " "case-ns convert dumbledore"
_completionTests_verifyCompletion "helm push-artifactory convert " "hermione harry ron"

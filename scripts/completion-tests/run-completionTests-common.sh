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
#

# This script allows to run completion tests for the bash shell.
# It also supports zsh completion tests, when zsh is used in bash-completion
# compatibility mode.
#
# To use this script one should create a test script which will:
# 1- source this script
# 2- source the completion script to be tested
# 3- call repeatedly the _completionTests_verifyCompletion() function passing it
#    the command line to be completed followed by the expected completion.
#
# For example, the test script can look like this:
#
# #!bash
# # source completionTests-base.sh
# # source helmCompletionScript.${SHELL_TYPE}
# # _completionTests_verifyCompletion "helm stat" "status"
#

# Don't use the new source <() form as it does not work with bash v3
source /dev/stdin <<- EOF
   $(helm completion ${SHELL_TYPE})
EOF

# Global variable to keep track of if a test has failed.
_completionTests_TEST_FAILED=0

# Run completion and indicate success or failure.
#    $1 is the command line that should be completed
#    $2 is the expected result of the completion
# If $1 = KFAIL indicates a Known failure
#    $1 = BFAIL indicates a Known failure only for bash
#    $1 = ZFAIL indicates a Known failure only for zsh
_completionTests_verifyCompletion() {
   local expectedFailure="NO"
   case $1 in
   [K,B,Z]FAIL)
      expectedFailure=$1
      shift
      ;;
   esac

   local cmdLine=$1
   local expected=$2
   local currentFailure=0

   result=$(_completionTests_complete "${cmdLine}")

   result=$(_completionTests_sort "$result")
   expected=$(_completionTests_sort "$expected")

   resultOut="$result"
   if [ "${#result}" -gt 50 ]; then
      resultOut="${result:0:50} <truncated>"
   fi

   if [ $expectedFailure = "KFAIL" ] ||
           ([ $expectedFailure = "BFAIL" ] && [ $SHELL_TYPE = "bash" ]) ||
           ([ $expectedFailure = "ZFAIL" ] && [ $SHELL_TYPE = "zsh" ]); then
      if [ "$result" = "$expected" ]; then
         _completionTests_TEST_FAILED=1
         currentFailure=1
         echo "UNEXPECTED SUCCESS: \"$cmdLine\" completes to \"$resultOut\""
      else
         echo "$expectedFailure: \"$cmdLine\" should complete to \"$expected\" but we got \"$resultOut\""
      fi
   elif [ "$result" = "$expected" ]; then
      echo "SUCCESS: \"$cmdLine\" completes to \"$resultOut\""
   else
      _completionTests_TEST_FAILED=1
      currentFailure=1
      echo "ERROR: \"$cmdLine\" should complete to \"$expected\" but we got \"$result\""
   fi

   return $currentFailure
}

_completionTests_disable_sort() {
    _completionTests_DISABLE_SORT=1
}

_completionTests_enable_sort() {
    unset _completionTests_DISABLE_SORT
}

_completionTests_sort() {
   if [ -n "${_completionTests_DISABLE_SORT}" ]; then
      # We use printf instead of echo as the $1 could be -n which would be
      # interpreted as an argument to echo
      printf "%s\n" "$1"
   else
      # We use printf instead of echo as the $1 could be -n which would be
      # interpreted as an argument to echo
      printf "%s\n" "$1" | sed -e 's/^ *//' -e 's/ *$//' | tr ' ' '\n' | sort -n | tr '\n' ' '
   fi
}

# Find the completion function associated with the binary.
# $1 is the first argument of the line to complete which allows
# us to find the existing completion function name.
_completionTests_findCompletionFunction() {
    binary=$(basename $1)
    # The below must work for both bash and zsh
    # which is why we use grep as complete -p $binary only works for bash
    local out=($(complete -p | grep ${binary}$))
    local returnNext=0
    for i in ${out[@]}; do
       if [ $returnNext -eq 1 ]; then
          echo "$i"
          return
       fi
       [ "$i" = "-F" ] && returnNext=1
    done
}

_completionTests_complete() {
   local cmdLine=$1


   # Set the bash completion variables which are
   # used for both bash and zsh completion
   COMP_LINE=${cmdLine}
   COMP_POINT=${#COMP_LINE}
   COMP_TYPE=9 # 9 is TAB
   COMP_KEY=9  # 9 is TAB
   COMP_WORDS=($(echo ${cmdLine}))

   COMP_CWORD=$((${#COMP_WORDS[@]}-1))
   # We must check for a space as the last character which will tell us
   # that the previous word is complete and the cursor is on the next word.
   [ "${cmdLine: -1}" = " " ] && COMP_CWORD=${#COMP_WORDS[@]}

   # Call the completion function associated with the binary being called.
   # Also redirect stderr to stdout so that the tests fail if anything is printed
   # to stderr.
   eval $(_completionTests_findCompletionFunction ${COMP_WORDS[0]}) 2>&1

   # Return the result of the completion.
   # We use printf instead of echo as the first completion could be -n which
   # would be interpreted as an argument to echo
   printf "%s\n" "${COMPREPLY[@]}"
}

_completionTests_exit() {
   # Return the global result each time.  This allows for the very last call to
   # this method to return the correct success or failure code for the entire script
   return $_completionTests_TEST_FAILED
}

# compopt, which is only available for bash 4, I believe,
# prints an error when it is being called outside of real shell
# completion.  Since it doesn't work anyway in our case, let's
# disable it to avoid the error printouts.
# Impacts are limited to completion of flags and even then
# for zsh and bash 3, it is not even available.
compopt() {
   :
}

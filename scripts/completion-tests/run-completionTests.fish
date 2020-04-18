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

echo "===================================================="
echo Running completions tests on (uname) with fish $version
echo "===================================================="

# Global variable to keep track of if a test has failed.
set -g _completionTests_TEST_FAILED 0

# Must set the path again for Fish as the path gets modified when the shell starts
set PATH $COMP_DIR/bin:$PATH

# Run completion and indicate success or failure.
#    $1 is the command line that should be completed
#    $2 is the expected result of the completion
function _completionTests_verifyCompletion
   set cmdLine $argv[1]
   set expected $argv[2]
   set currentFailure 0

   set result (complete --do-complete "$cmdLine")

   set result (_completionTests_sort "$result")
   set expected (_completionTests_sort "$expected")

   set resultOut "$result"
   if test (string length -- "$result") -gt 50
      set resultOut (string sub --length 50 -- $result) "<truncated>"
   end

   if test "$result" = "$expected"
      echo "SUCCESS: \"$cmdLine\" completes to \"$resultOut\""
   else
      set _completionTests_TEST_FAILED 1
      set currentFailure 1
      echo "ERROR: \"$cmdLine\" should complete to \"$expected\" but we got \"$result\""
   end

   return $currentFailure
end

function _completionTests_disable_sort
    set -g _completionTests_DISABLE_SORT 1
end

function _completionTests_enable_sort
    set -e _completionTests_DISABLE_SORT
end

function _completionTests_sort
   if test -n "$_completionTests_DISABLE_SORT"
      # We use printf instead of echo as the $1 could be -n which would be
      # interpreted as an argument to echo
      printf "%s\n" "$argv[1]"
   else
      # We use printf instead of echo as the $1 could be -n which would be
      # interpreted as an argument to echo
      printf "%s\n" "$argv[1]" | sed -e 's/^ *//' -e 's/ *$//' | tr ' ' '\n' | sort -n | tr '\n' ' '
   end
end

function _completionTests_exit
   # Return the global result each time.  This allows for the very last call to
   # this method to return the correct success or failure code for the entire script
   return $_completionTests_TEST_FAILED
end

# Load all existing completions that fish may already know about
# so that the helm completion script can delete them
complete --do-complete "helm " > /dev/null
helm completion fish --no-descriptions | source

source $COMP_DIR/completionTests-common.sh
source $COMP_DIR/completionTests.fish

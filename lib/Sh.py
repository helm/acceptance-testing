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

import os
import common
from ClusterProvider import auth_wrap

needs_cluster = False

class Sh(common.CommandRunner):
    def require_cluster(self, require):
        global needs_cluster
        if require == "True" or require == "true":
            needs_cluster = True
        else:
            needs_cluster = False

    def wrap(self, cmd):
        global needs_cluster
        if needs_cluster == True:
            return auth_wrap(cmd)
        return cmd

    def Run(self, cmd):
        self.run_command(self.wrap(cmd))

    def should_pass(self, cmd):
        self.Run(cmd)
        self.return_code_should_be(0)

    def should_fail(self, cmd):
        self.Run(cmd)
        self.return_code_should_not_be(0)

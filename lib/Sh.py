import os
import common
from Kind import kind_auth_wrap

needs_cluster = True

class Sh(common.CommandRunner):
    def require_cluster(self, require):
        global needs_cluster
        needs_cluster = require

    def wrap(self, cmd):
        global needs_cluster
        if needs_cluster == True:
            return kind_auth_wrap(cmd)
        return cmd

    def Run(self, cmd):
        self.run_command(self.wrap(cmd))

    def Pass(self, cmd):
        self.Run(cmd)
        self.return_code_should_be(0)

    def Fail(self, cmd):
        self.Run(cmd)
        self.return_code_should_not_be(0)

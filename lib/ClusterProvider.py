import common
import os
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn


ROBOT_LIBRARY_SCOPE = 'SUITE'
AUTH_COMMAND = ''


def auth_wrap(cmd):
    return AUTH_COMMAND+' && '+cmd


class ClusterProvider(common.CommandRunner):
    def __init__(self):
        self.provider = os.getenv("CLUSTER_PROVIDER", default='kind')
        self.cluster_name = ''

    def get_current_version(self):
        return BuiltIn().get_variable_value('${version}')

    def create_test_cluster_with_kubernetes_version(self, kube_version):
        global AUTH_COMMAND
        self.cluster_name = f'helm-acceptance-test-{kube_version}'
        self.call_cluster_provisioner_function(
            'create_cluster')
        AUTH_COMMAND = self.call_cluster_provisioner_function(
            'get_cluster_auth')

    def wait_for_cluster(self):
        return self.call_cluster_provisioner_function('wait_for_cluster')

    def delete_test_cluster(self):
        return self.call_cluster_provisioner_function('delete_cluster')

    def cleanup_all_test_clusters(self):
        return self.call_cluster_provisioner_function('cleanup_all_test_clusters')

    def get_cluster_auth(self):
        return self.call_cluster_provisioner_function('get_cluster_auth')

    def call_cluster_provisioner_function(self, func, args=''):
        c = f'{self.provider}_{func} {self.cluster_name} {self.get_current_version()} {args}'
        self.run_command(c)
        if self.rc != 0:
            raise Exception(f'Failed to run cmd {c} received output {self.stdout}')
        return self.stdout

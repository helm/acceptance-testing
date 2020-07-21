import os
import common
from ClusterProvider import auth_wrap

TEST_CHARTS_ROOT_DIR = os.path.abspath(os.path.dirname(os.path.realpath(__file__)) +'/../testdata/charts')

class Helm(common.CommandRunner):
    def install_test_chart(self, release_name, test_chart, extra_args):
        chart_path = TEST_CHARTS_ROOT_DIR+'/'+test_chart
        cmd = 'helm install '+release_name+' '+chart_path+' '+extra_args
        self.run_command(auth_wrap(cmd))

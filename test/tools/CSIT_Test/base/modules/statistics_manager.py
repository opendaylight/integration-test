"""
CSIT test tools.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-01
"""

import sys

sys.path.append('..')
from restlib import *
from testmodule import TestModule

sys.path.remove('..')


class StatisticsManager(TestModule):
    """
    Test for the statistics manager.
    Start 2-layer tree topology network. e.g., in Mininet, run  'sudo mn --controller=remote,ip=127.0.0.1 --mac --topo tree,2'
    """

    def __init__(self, restSubContext='/controller/nb/v2/statistics', user=DEFAULT_USER, password=DEFAULT_PWD,
                 container=DEFAULT_CONTAINER, contentType='json', prefix=DEFAULT_PREFIX):
        super(self.__class__, self).__init__(restSubContext, user, password, container, contentType, prefix)

    def get_flow_stats(self):
        """
        The name is suggested to match the NB API.
        Show the flow statistics
        """
        return super(self.__class__, self).get_entries('flow')

    def get_port_stats(self):
        """
        The name is suggested to match the NB API.
        Show the port statistics
        """
        return super(self.__class__, self).get_entries('port')

    def get_table_stats(self):
        """
        The name is suggested to match the NB API.
        Show the table statistics
        """
        return super(self.__class__, self).get_entries('table')

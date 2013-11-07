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


class ContainerManager(TestModule):
    """
    Test for the container manager.
    Start 2-layer tree topology network. e.g., in Mininet, run  'sudo mn --controller=remote,ip=127.0.0.1 --mac --topo tree,2'
    """

    def __init__(self, restSubContext='/controller/nb/v2/containermanager', user=DEFAULT_USER, password=DEFAULT_PWD,
                 container=None, contentType='json', prefix=DEFAULT_PREFIX):
        super(self.__class__, self).__init__(restSubContext, user, password, container, contentType, prefix)

    def get_containers(self):
        """
        The name is suggested to match the NB API.
        Show the containers
        """
        return super(self.__class__, self).get_entries('containers')

    def add_container(self, name, body):
        """
        Add a container
        """
        self.container = 'container'
        super(self.__class__, self).add_entry('containermanager', name, body)

    def remove_container(self, name):
        """
        Remove a container
        """
        self.container = 'container'
        super(self.__class__, self).remove_entry('containermanager', name)

    def test_container_operations(self, name, body):
        """
        Test subnet operations, like adding and removeing a subnet.
        >>> ContainerManager().test_container_operations('cont1',{'container':'cont1','flowSpecs': [], 'staticVlan':'10','nodeConnectors':["OF|1@OF|00:00:00:00:00:00:00:01","OF|23@OF|00:00:00:00:00:00:20:21"]})
        True
        """
        return super(self.__class__, self).test_add_remove_operations('containers', 'container', name, body,
                                                                      'container-config')

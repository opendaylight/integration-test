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


class ArpHandler(TestModule):
    """
    Test for the arp handler.
    Start 2-layer tree topology network. e.g., in Mininet, run  'sudo mn --controller=remote,ip=127.0.0.1 --mac --topo tree,2'
    """

    def __init__(self, restSubContext='/controller/nb/v2/subnetservice', user=DEFAULT_USER, password=DEFAULT_PWD,
                 container=DEFAULT_CONTAINER, contentType='json', prefix=DEFAULT_PREFIX):
        super(self.__class__, self).__init__(restSubContext, user, password, container, contentType, prefix)

    def get_subnets(self):
        """
        The name is suggested to match the NB API.
        list all subnets and their properties.
        """
        return super(self.__class__, self).get_entries('subnets')

    def add_subnet_gateway(self, name, body):
        """
        Add a subnet gateway.
        """
        super(self.__class__, self).add_entry('subnet', name, body)

    def remove_subnet_gateway(self, name):
        """
        Remove a subnet gateway.
        """
        super(self.__class__, self).remove_entry('subnet', name)

    def test_subnet_operations(self, name, body):
        """
        Test subnet operations, like adding and removeing a subnet.
        >>> ArpHandler().test_subnet_operations('test',{'name':'test','subnet':'10.0.0.254/8'})
        True
        """
        return super(self.__class__, self).test_add_remove_operations('subnets', 'subnet', name, body, 'subnetConfig')


if __name__ == '__main__':
    print 'arp handler'
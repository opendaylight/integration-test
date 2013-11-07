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


class ForwardingManager(TestModule):
    """
    Test for the forwarding manager.
    Start 2-layer tree topology network. e.g., in Mininet, run  'sudo mn --controller=remote,ip=127.0.0.1 --mac --topo tree,2'
    """
    def __init__(self,restSubContext='/controller/nb/v2/staticroute',user=DEFAULT_USER, password=DEFAULT_PWD,container=DEFAULT_CONTAINER,contentType='json',prefix=DEFAULT_PREFIX):
       super(self.__class__,self).__init__(restSubContext,user,password,container,contentType,prefix)

    def get_routes(self):
        """
        The name is suggested to match the NB API.
        list all routes
        """
        return super(self.__class__, self).get_entries('routes')

    def add_static_route(self, name, body):
        """
        Add a static route.
        """
        r = super(self.__class__, self).add_entry('route', name, body)

    def remove_static_route(self, name):
        """
        Remove a static route
        """
        r = super(self.__class__, self).remove_entry('route', name)

    def test_static_route_operations(self, name, body):
        """
        Test static route operations, like adding and removeing a route.
        >>> ForwardingManager().test_static_route_operations('route1',{'name':'route1','prefix':'192.168.1.0/24','nextHop':'10.0.0.2'})
        True
        """
        return super(self.__class__, self).test_add_remove_operations('routes', 'route', name, body, 'staticRoute')

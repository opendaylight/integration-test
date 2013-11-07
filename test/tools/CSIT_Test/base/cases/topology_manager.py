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


class TopologyManager(TestModule):
    """
    Test for the topology manager.
    Start 2-layer tree topology network. e.g., in Mininet, run  'sudo mn --controller=remote,ip=127.0.0.1 --mac --topo tree,2'
    """

    def __init__(self, restSubContext='/controller/nb/v2/topology', user=DEFAULT_USER, password=DEFAULT_PWD,
                 container=DEFAULT_CONTAINER, contentType='json', prefix=DEFAULT_PREFIX):
        super(self.__class__, self).__init__(restSubContext, user, password, container, contentType, prefix)

    def get_topology(self):
        """
        The name is suggested to match the NB API.
        Show the topology
        >>> TopologyManager().get_topology()
        True
        """
        result = []
        r = super(self.__class__, self).get_entries()
        if r:
            v = [e['edge'] for e in r['edgeProperties']]
            result.append({u'tailNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:01'},
                                                  u'type': u'OF', u'id': u'2'},
                           u'headNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:03'},
                                                  u'type': u'OF', u'id': u'3'}} in v)
            result.append({u'tailNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:03'},
                                                  u'type': u'OF', u'id': u'3'},
                           u'headNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:01'},
                                                  u'type': u'OF', u'id': u'2'}} in v)
            result.append({u'tailNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:02'},
                                                  u'type': u'OF', u'id': u'3'},
                           u'headNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:01'},
                                                  u'type': u'OF', u'id': u'1'}} in v)
            result.append({u'tailNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:01'},
                                                  u'type': u'OF', u'id': u'1'},
                           u'headNodeConnector': {u'node': {u'type': u'OF', u'id': u'00:00:00:00:00:00:00:02'},
                                                  u'type': u'OF', u'id': u'3'}} in v)
            print result == [True, True, True, True]

    def get_userlinks(self):
        """
        The name is suggested to match the NB API.
        Show the userlinks.
        """
        suffix = 'userLinks'
        r = super(self.__class__, self).read(suffix)
        if r:
            return r

    def add_userlink(self, name, body):
        """
        Add a userlink.
        """
        suffix = 'userLink'
        r = super(self.__class__, self).update(suffix + '/' + name, body)
        return r

    def remove_userlink(self, name):
        """
        Remove a userlink.
        """
        suffix = 'userLink'
        r = super(self.__class__, self).delete(suffix + '/' + name)
        return r

    def test_userlink_operations(self, name, body):
        """
        Test userlink operations, like adding and removing.
        >>> TopologyManager().test_userlink_operations('link1', {'status':'Success','name':'link1','srcNodeConnector':'OF|1@OF|00:00:00:00:00:00:00:02','dstNodeConnector':'OF|1@OF|00:00:00:00:00:00:00:03'})
        True
        """
        return super(self.__class__, self).test_add_remove_operations('userLinks', 'userLink', name, body, 'userLinks')

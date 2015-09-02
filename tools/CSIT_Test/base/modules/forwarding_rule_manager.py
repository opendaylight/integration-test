"""
CSIT test tools.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-05
"""

import sys

sys.path.append('..')
from restlib import *
from testmodule import TestModule

sys.path.remove('..')


class ForwardingRuleManager(TestModule):
    """
    Test for the forwarding rule manager.
    Start 2-layer tree topology network. e.g., in Mininet, run  'sudo mn --controller=remote,ip=127.0.0.1 --mac --topo tree,2'
    """

    def __init__(self, restSubContext='/controller/nb/v2/flowprogrammer', user=DEFAULT_USER, password=DEFAULT_PWD,
                 container=DEFAULT_CONTAINER, contentType='json', prefix=DEFAULT_PREFIX):
        super(self.__class__, self).__init__(restSubContext, user, password, container, contentType, prefix)

    def get_flows(self):
        """
        The name is suggested to match the NB API.
        Show the flows
        """
        return super(self.__class__, self).get_entries('')

    def add_flow_to_node(self, node_type, node_id, name, body):
        suffix = 'node/' + node_type + '/' + node_id + '/staticFlow'
        r = super(self.__class__, self).add_entry(suffix, name, body)

    def remove_flow_from_node(self, node_type, node_id, name):
        suffix = 'node/' + node_type + '/' + node_id + '/staticFlow'
        r = super(self.__class__, self).remove_entry(suffix, name)

    def test_flow_operations(self, node_type, node_id, name, body):
        """
        Test the add,remove,show actions on flows.
        >>> body = {'installInHw':'true','name':'flow1','node':{'id':'00:00:00:00:00:00:00:02','type':'OF'},'priority':'1','etherType':'0x800','nwDst':'10.0.0.1/32','actions':['OUTPUT=1']}
        >>> ForwardingRuleManager().test_flow_operations('OF','00:00:00:00:00:00:00:02','flow1',body)
        True
        >>> body = {'installInHw':'true','name':'flow2','node':{'id':'00:00:00:00:00:00:00:02','type':'OF'},'priority':'1','etherType':'0x800','nwDst':'10.0.0.2/32','actions':['OUTPUT=2']}
        >>> ForwardingRuleManager().test_flow_operations('OF','00:00:00:00:00:00:00:02','flow2',body)
        True
        """
        result = []
        #current flow table should be empty.
        r = self.get_flows()
        result.append(body not in r['flowConfig'])
        #Add a flow
        self.add_flow_to_node(node_type, node_id, name, body)
        r = self.get_flows()
        result.append(body in r['flowConfig'])
        #Remove the flow and test if succeed
        if result == [True, True]:
            self.remove_flow_from_node(node_type, node_id, name)
            r = self.get_flows()
            result.append(body not in r['flowConfig'])
        return result == [True, True, True]

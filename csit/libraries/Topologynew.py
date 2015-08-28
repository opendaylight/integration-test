"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-10
"""
import re
from robot.libraries.BuiltIn import BuiltIn
import Common


class Topologynew(object):
    '''
    Topology class provide topology database and provide many method to get property of topology.

    node_boilerplate = {u'type': u'MD_SAL', u'id': u'openflow:%d'}
    '''
    topo_nodes_db = [
        [],
        [{u'type': u'MD_SAL', u'id': u'openflow:1'}],
        [{u'type': u'MD_SAL', u'id': u'openflow:1'},
         {u'type': u'MD_SAL', u'id': u'openflow:2'},
         {u'type': u'MD_SAL', u'id': u'openflow:3'}]
        ]

    def __init__(self):
        self.builtin = BuiltIn()

    def get_nodes_from_topology(self, topo_level):
        '''
        get nodes from topology database by topology tree level
        '''
        if isinstance(topo_level, str) or isinstance(topo_level, unicode):
            if topo_level.isdigit():
                topo_level = int(topo_level)
                if topo_level <= 0:
                    return None
                return self.topo_nodes_db[topo_level]
            else:
                return None
        elif isinstance(topo_level, int):
            if topo_level <= 0:
                return None
            return self.topo_nodes_db[topo_level]
        else:
            return None

    def get_nodes_from_tree_topo(self, topo, exceptroot="0"):
        '''
        This function generates a dictionary that contains type and id of each node.
        It follows tree level topology.
        @parameter topo: either an interer (in this case, depth is set and fanout will be 2)
                         or a string in format of "(a,b)"   (a and b are integers and they
                         stands for depth and fanout respectively)
        @return array of dicitonary objects that contains info about each node
        '''
        depth = 0
        fanout = 2
        if isinstance(topo, str) or isinstance(topo, unicode):
            t = tuple(int(v) for v in re.findall("[0-9]+", topo))
            if len(t) == 1:
                depth = t[0]
            elif len(t) == 2:
                depth = t[0]
                fanout = t[1]
            else:
                return None                 # topology consists of two parameters: depth and fanout
        elif isinstance(topo, int):
            depth = topo
        else:
            return None                     # topo parameter is not given in a desired way

        num_nodes = Common.num_of_nodes(depth, fanout)
        nodelist = []
        for i in xrange(1, num_nodes+1):
            temp = {"id": "00:00:00:00:00:00:00:%s" % format(i, '02x'), "type": "OF"}
            nodelist.append(temp)
        if int(exceptroot):
            del nodelist[0]
        return nodelist

    def get_ids_of_leaf_nodes(self, fanout, depth):
        '''
        For a tree structure, it numerates leaf nodes
        by following depth-first strategy
        @parameter  fanout: fanout of tree
        @parameter  depth:  total depth of a tree
        @return     leafnodes:  list of ids of leaf nodes
        '''
        leafnodes = []
        self._enumerate_nodes(0, 1, 1, fanout, depth-1, leafnodes)
        return leafnodes

    def _enumerate_nodes(self, currentdepth, nodeid, currentbranch, fanout, depth, leafnodes):
        if currentdepth == depth:
            leafnodes.append("00:00:00:00:00:00:00:%s" % format(nodeid, '02x'))
            return 1
        nodes = 1
        for i in xrange(1,  fanout+1):
            nodes += self._enumerate_nodes(currentdepth+1, nodeid+nodes, i, fanout, depth, leafnodes)
        return nodes

if __name__ == '__main__':
    topologynew = Topologynew()
    # print topologynew.get_nodes_from_tree_topo(2)
    # print topologynew.get_nodes_from_tree_topo('2')
    print topologynew.get_nodes_from_tree_topo('(2,3)')
    # print topologynew.get_ids_of_leaf_nodes(2,2 )#, depth)

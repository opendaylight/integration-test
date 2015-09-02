"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-10
"""
import string
import robot
from robot.libraries.BuiltIn import BuiltIn

class Topology(object):
    '''
    Topology class provide topology database and provide many method to get property of topology.
    '''
    topo_nodes_db=[[],
            [{u'type': u'OF', u'id': u'00:00:00:00:00:00:00:01'}],
            [{u'type': u'OF', u'id': u'00:00:00:00:00:00:00:01'},{u'type': u'OF', u'id': u'00:00:00:00:00:00:00:02'},{u'type': u'OF', u'id': u'00:00:00:00:00:00:00:03'}]]
    def __init__(self):
        self.builtin = BuiltIn()

    def get_nodes_from_topology(self,topo_level):
        '''
        get nodes from topology database by topology tree level
        '''
        if isinstance(topo_level, str) or isinstance(topo_level, unicode):
            if topo_level.isdigit():
                topo_level=int(topo_level)
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

if __name__ == '__main__':
    topology = Topology()
    print topology.get_nodes_from_topology(2)
    print topology.get_nodes_from_topology('2')

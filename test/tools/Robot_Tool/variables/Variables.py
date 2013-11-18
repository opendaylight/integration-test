"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-14
"""
import collections

# Global variables
CONTROLLER_IP = '127.0.0.1'
PORT = '8080'
PREFIX = 'http://' + CONTROLLER_IP + ':' + PORT
CONTAINER = 'default'
USER = 'admin'
PWD = 'admin'
AUTH = [u'admin',u'admin']
ODL_CONTROLLER_SESSION=None
TOPO_TREE_LEVEL=2

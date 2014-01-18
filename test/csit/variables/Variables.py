"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-14
"""
import collections

# Global variables
CONTROLLER = '10.125.136.52'
PORT = '8080'
PREFIX = 'http://' + CONTROLLER + ':' + PORT
CONTAINER = 'default'
USER = 'admin'
PWD = 'admin'
AUTH = [u'admin',u'admin']
HEADERS={'Content-Type': 'application/json'}
HEADERS_XML={'Content-Type': 'application/xml'}
ODL_CONTROLLER_SESSION=None
TOPO_TREE_LEVEL=2

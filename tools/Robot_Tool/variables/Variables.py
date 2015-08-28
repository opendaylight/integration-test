"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-14
"""

# Global variables
CONTROLLER = '127.0.0.1'
PORT = '8080'
PREFIX = 'http://' + CONTROLLER + ':' + PORT
CONTAINER = 'default'
USER = 'admin'
PWD = 'admin'
AUTH = [u'admin', u'admin']
HEADERS = {'Content-Type': 'application/json'}
ODL_CONTROLLER_SESSION = None
TOPO_TREE_LEVEL = 2

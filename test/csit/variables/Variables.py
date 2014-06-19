"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-14
"""
import collections

# Global variables
CONTROLLER = '127.0.0.1'
PORT = '8080'
PREFIX = 'http://' + CONTROLLER + ':' + PORT
CONTAINER = 'default'
USER = 'admin'
PWD = 'admin'
AUTH = [u'admin',u'admin']
HEADERS={'Content-Type': 'application/json'}
HEADERS_XML={'Content-Type': 'application/xml'}
ACCEPT_XML={'Accept': 'application/xml'}
ODL_CONTROLLER_SESSION=None
TOPO_TREE_LEVEL=2

# VTN Coordinator Variables
VTNC = '127.0.0.1'
VTNCPORT = '8083'
VTNC_PREFIX = 'http://' + VTNC + ':' + VTNCPORT
VTNC_HEADERS={'Content-Type': 'application/json', 'username' : 'admin' , 'password' : 'adminpass'}

VTNWEBAPI='/vtn-webapi'
#controllers URL
CTRLS_CREATE='controllers.json'
CTRLS='controllers'
SW='switches'

#vtn URL
VTNS_CREATE='vtns.json'
VTNS='vtns'

#vbridge URL
VBRS_CREATE='vbridges.json'
VBRS='vbridges'

#interfaces URL
VBRIFS_CREATE='interfaces.json'
VBRIFS='interfaces'

#portmap URL
PORTMAP_CREATE='portmap.json'

#vlanmap URL
VLANMAP_CREATE='vlanmaps.json'

#ports URL
PORTS='ports/detail.json'

"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-14
"""

# Global variables
CONTROLLER = '127.0.0.1'
PORT = '8080'
RESTPORT = '8282'
RESTCONFPORT = '8181'
PREFIX = 'http://' + CONTROLLER + ':' + PORT
PROMPT = '>'
CONTAINER = 'default'
USER = 'admin'
PWD = 'admin'
AUTH = [u'admin', u'admin']
SCOPE = 'sdn'
HEADERS = {'Content-Type': 'application/json'}
HEADERS_XML = {'Content-Type': 'application/xml'}
ACCEPT_XML = {'Accept': 'application/xml'}
ODL_CONTROLLER_SESSION = None
TOPO_TREE_LEVEL = 2
TOPO_TREE_DEPTH = 3
TOPO_TREE_FANOUT = 2

# KARAF Varaiable
KARAF_SHELL_PORT = '8101'
KARAF_PROMPT = 'opendaylight-user'
KARAF_USER = 'karaf'
KARAF_PASSWORD = 'karaf'

# VM Environment Variables
LINUX_PROMPT = '>'

# VTN Coordinator Variables
VTNC = '127.0.0.1'
VTNCPORT = '8083'
VTNC_PREFIX = 'http://' + VTNC + ':' + VTNCPORT
VTNC_HEADERS = {'Content-Type': 'application/json', 'username': 'admin', 'password': 'adminpass'}

VTNWEBAPI = '/vtn-webapi'
# controllers URL
CTRLS_CREATE = 'controllers.json'
CTRLS = 'controllers'
SW = 'switches'

# vtn URL
VTNS_CREATE = 'vtns.json'
VTNS = 'vtns'

# vbridge URL
VBRS_CREATE = 'vbridges.json'
VBRS = 'vbridges'

# interfaces URL
VBRIFS_CREATE = 'interfaces.json'
VBRIFS = 'interfaces'

# portmap URL
PORTMAP_CREATE = 'portmap.json'

# vlanmap URL
VLANMAP_CREATE = 'vlanmaps.json'

# ports URL
PORTS = 'ports/detail.json'

# Common APIs
CONFIG_NODES_API = '/restconf/config/opendaylight-inventory:nodes'
OPERATIONAL_NODES_API = '/restconf/operational/opendaylight-inventory:nodes'
OPERATIONAL_TOPO_API = '/restconf/operational/network-topology:network-topology'
CONFIG_TOPO_API = '/restconf/config/network-topology:network-topology'
CONTROLLER_CONFIG_MOUNT = ('/restconf/config/network-topology:network-topology/topology'
                           '/topology-netconf/node/controller-config/yang-ext:mount')

# TOKEN
AUTH_TOKEN_API = '/oauth2/token'
REVOKE_TOKEN_API = '/oauth2/revoke'

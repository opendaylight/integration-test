#! /usr/bin/python


# Global variables
# Test Server details where openstack client is running
# ODL_RELEASE = "16A"
MANUALIP_CONFIG = True
ODL_DATASTORE_CONFIG = "NO"
HIPVS_VERSION = "1.5"
HIPVS_HOME = "/opt/HIPVS/hipvs-dp/scripts/"
CERROS_VMPROMPT = 'login:'
ZERO_VMPROMPT = 'Select:'
imagetype = "ZEROSHELL"
HIPVSBIN = "service hipvs"
TEST_SERVER_USERNAME = "root"
TEST_SERVER_PASSWORD = "admin123"
REMOTE_SERVER_USERNAME = "root"
REMOTE_SERVER_PASSWORD = "admin123"
CONTROLLER = '127.0.0.1'
PORT = '8080'
RESTPORT = '8282'
RESTCONFPORT = '8181'
TENANT_ID = '6c53df3a-3456-11e5-a151-feff819cdc9f'
TENANT_ID_15A = 'dc0a56976ff94bb0ae7b46e0f254dad8'
PREFIX = 'http://' + CONTROLLER + ':' + PORT
HEADERS = {'Content-Type': 'application/json'}
HEADERS_XML = {'Content-Type': 'application/xml'}
ACCEPT_XML = {'Accept': 'application/xml'}
AUTH = [u'admin', u'admin']
SCOPE = 'sdn'
POST_RESPONSE_CODE = 204
DELETE_RESPONSE_CODE = 200
GET_RESPONSE_CODE = 200
UPDATE_RESPONSE_CODE = 200
# For 15A
POST_RESPONSE_CODE_15A = 201
DELETE_RESPONSE_CODE_15A = 204

# KARAF Variaable
KARAF_SHELL_PORT = '8101'
KARAF_PROMPT = 'opendaylight-user'
KARAF_USER = 'karaf'
KARAF_PASSWORD = 'karaf'

# ports URL
PORTS = 'ports/detail.json'

# Common APIs
ODLNEUTRON_DATA = "/restconf/config/neutron:neutron/"
ODLNEUTRON = "/controller/nb/v2/neutron/"
ODLREST = "/restconf/config/opendaylight-inventory:nodes/"
L3VPNREST = "/restconf/operations/neutronvpn"
# TOKEN
AUTH_TOKEN_API = '/oauth2/token'
REVOKE_TOKEN_API = '/oauth2/revoke'

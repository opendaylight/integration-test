"""
Definitions of target field paths widely used throughout the Topoprocessing suites.
"""
#NT target fields
ISIS_NODE_TE_ROUTER_ID_IPV4 = 'l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4'
ISIS_NODE_TE_ROUTER_ID_IPV6 = 'l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv6'
IGP_LINK_METRIC = 'l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:metric'
IGP_LINK_NAME = 'l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name'
OVSDB_OFPORT = 'ovsdb:ofport'
OVSDB_OVS_VERSION = 'ovsdb:ovs-version'
OVSDB_TP_NAME = 'ovsdb:name'

#Inventory target fields
OPENFLOW_NODE_IP_ADDRESS = 'flow-node-inventory:ip-address'
OPENFLOW_NODE_SERIAL_NUMBER = 'flow-node-inventory:serial-number'
OPENFLOW_NODE_CONNECTOR_PORT_NUMBER = 'flow-node-inventory:port-number'
OPENFLOW_NODE_CONNECTOR_MAXIMUM_SPEED = 'flow-node-inventory:maximum-speed'
OPENFLOW_NODE_CONNECTOR_NAME = 'flow-node-inventory:name'

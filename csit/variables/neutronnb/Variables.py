"""Variables for interacting with ODL's Neutron Northbound API."""

import os

templates_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "request_templates")

# Paths to templates of HTTP request data sections for Neutron NB API calls
CREATE_EXT_NET_TEMPLATE = os.path.join(templates_dir, "create_ext_net.json")
CREATE_EXT_SUBNET_TEMPLATE = os.path.join(templates_dir, "create_ext_subnet.json")
CREATE_TNT_NET_TEMPLATE = os.path.join(templates_dir, "create_tnt_net.json")
CREATE_TNT_SUBNET_TEMPLATE = os.path.join(templates_dir, "create_tnt_subnet.json")
CREATE_ROUTER_TEMPLATE = os.path.join(templates_dir, "create_router.json")
CREATE_PORT_RTR_GATEWAY_TEMPLATE = os.path.join(templates_dir, "create_port_rtr_gateway.json")

# TODO: Generate dynamically
EXT_NET1_ID = "7da709ff-397f-4778-a0e8-994811272fdb"
TNT1_ID = "cde2563ead464ffa97963c59e002c0cf"
TNT1_NET1_ID = "12809f83-ccdf-422c-a20a-4ddae0712655"
TNT1_SUBNET1_ID = "6c496958-a787-4d8c-9465-f4c4176652e8"
TNT1_VM1_PORT_ID = "341ceaca-24bf-4017-9b08-c3180e86fd24"
TNT1_VM1_MAC = "FA:16:3E:8E:B8:05"
TNT1_VM1_DEVICE_ID = "20e500c3-41e1-4be0-b854-55c710a1cfb2"
TNT1_NET1_NAME = "net1"
TNT1_NET1_SEGM = "1062"
TNT1_RTR_ID = "e09818e7-a05a-4963-9927-fc1dc6f1e844"
EXT_SUBNET1_ID = "00289199-e288-464a-ab2f-837ca67101a7"
TNT1_SUBNET1_NAME = "subnet1"
NEUTRON_PORT_TNT1_RTR_GW = "8ddd29db-f417-4917-979f-b01d4b1c3e0d"

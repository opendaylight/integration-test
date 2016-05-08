#!/usr/bin/python

tenantId = '6c53df3a-3456-11e5-a151-feff819cdc9f'
true = "true"
false = "false"

test_neutron_port1 = "79ad0001-19e0-489c-9505-cc70f9eb0001"
test_neutron_port2 = "79ad0002-19e0-489c-9505-cc70f9eb0002"
test_neutron_port3 = "79ad0003-19e0-489c-9505-cc70f9eb0003"
test_neutron_port4 = "79ad0004-19e0-489c-9505-cc70f9eb0004"
test_neutron_subnet1 = "6c496958-a787-4d8c-9465-f4c417660001"
test_neutron_subnet2 = "6c496958-a787-4d8c-9465-f4c417660002"
test_neutron_network1 = "12809f83-ccdf-422c-a20a-4ddae0710001"
test_neutron_network2 = "12809f83-ccdf-422c-a20a-4ddae0710002"

neutron_test_network_1 = {
 "network": {
   "id": "12809f83-ccdf-422c-a20a-4ddae0710001",
   "tenant_id": tenantId,
   "name": "mynetwork1",
   "admin_state_up": true,
   "shared": false,
   "router:external": false,
   "provider:network_type": "vxlan",
   "status": "ACTIVE",
   "vlan_transparent": false,
   'subnets': []
   }
 }

neutron_test_network_2 = {
 "network": {
   "id": "12809f83-ccdf-422c-a20a-4ddae0710002",
   "tenant_id": tenantId,
   "name": "mynetwork2",
   "admin_state_up": true,
   "shared": false,
   "router:external": false,
   "provider:network_type": "vxlan",
   "status": "ACTIVE",
   "vlan_transparent": false,
   'subnets': []
   }
 }

neutron_test_subnet_1 = {
 "subnet": {
   "id": "6c496958-a787-4d8c-9465-f4c417660001",
   "tenant_id": tenantId,
   "network_id": "12809f83-ccdf-422c-a20a-4ddae0710001",
   "name": "mysubnet1",
   "ip_version": 4,
   "cidr": "20.1.1.0/24",
   "gateway_ip": "20.1.1.1",
   "dns_nameservers": [],
   "allocation_pools": [{"start": "20.1.1.2", "end": "20.1.1.254"}],
   "host_routes": [],
   "enable_dhcp": true,
   "ipv6_address_mode": "null",
   "ipv6_ra_mode": "null"
   }
 }

neutron_test_subnet_2 = {
 "subnet": {
   "id": "6c496958-a787-4d8c-9465-f4c417660002",
   "tenant_id": tenantId,
   "network_id": "12809f83-ccdf-422c-a20a-4ddae0710002",
   "name": "mysubnet2",
   "ip_version": 4,
   "cidr": "30.1.1.0/24",
   "gateway_ip": "30.1.1.1",
   "dns_nameservers": [],
   "allocation_pools": [{"start": "30.1.1.2", "end": "30.1.1.254"}],
   "host_routes": [],
   "enable_dhcp": true,
   "ipv6_address_mode": "null",
   "ipv6_ra_mode": "null"
   }
 }

neutron_test_port_1 = {
 "port": {
   "id": "79ad0001-19e0-489c-9505-cc70f9eb0001",
   "tenant_id": tenantId,
   "network_id": "12809f83-ccdf-422c-a20a-4ddae0710001",
   "name": "myport1",
   "admin_state_up": true,
   "status": "ACTIVE",
   "mac_address": "00:16:3E:CB:11:0C",
   "fixed_ips": [{
     "ip_address": "20.1.1.2",
     "subnet_id": "6c496958-a787-4d8c-9465-f4c417660001"}],
   "device_id": "",
   "device_owner": "",
   "binding:host_id": "ubuntu",
   "binding:vnic_type": "normal",
   "binding:vif_type": "ovs",
   "binding:vif_details": [{"port_filter": false}]
   }
 }

neutron_test_port_2 = {
 "port": {
   "id": "79ad0002-19e0-489c-9505-cc70f9eb0002",
   "tenant_id": tenantId,
   "network_id": "12809f83-ccdf-422c-a20a-4ddae0710001",
   "name": "myport2",
   "admin_state_up": true,
   "status": "ACTIVE",
   "mac_address": "00:16:3E:6C:F1:AA",
   "fixed_ips": [{
     "ip_address": "20.1.1.3",
     "subnet_id": "6c496958-a787-4d8c-9465-f4c417660001"}],
   "device_id": "",
   "device_owner": "",
   "binding:host_id": "ubuntu",
   "binding:vnic_type": "normal",
   "binding:vif_type": "ovs",
   "binding:vif_details": [{"port_filter": false}]
   }
 }

neutron_test_port_3 = {
 "port": {
   "id": "79ad0003-19e0-489c-9505-cc70f9eb0003",
   "tenant_id": tenantId,
   "network_id": "12809f83-ccdf-422c-a20a-4ddae0710002",
   "name": "myport3",
   "admin_state_up": true,
   "status": "ACTIVE",
   "mac_address": "00:16:3E:44:AF:8C",
   "fixed_ips": [{
     "ip_address": "30.1.1.4",
     "subnet_id": "6c496958-a787-4d8c-9465-f4c417660002"}],
   "device_id": "",
   "device_owner": "",
   "binding:host_id": "ubuntu",
   "binding:vnic_type": "normal",
   "binding:vif_type": "ovs",
   "binding:vif_details": [{"port_filter": false}]
   }
 }

neutron_test_port_4 = {
 "port": {
   "id": "79ad0004-19e0-489c-9505-cc70f9eb0004",
   "tenant_id": tenantId,
   "network_id": "12809f83-ccdf-422c-a20a-4ddae0710002",
   "name": "myport4",
   "admin_state_up": true,
   "status": "ACTIVE",
   "mac_address": "00:16:3E:92:5C:9F",
   "fixed_ips": [{
     "ip_address": "30.1.1.5",
     "subnet_id": "6c496958-a787-4d8c-9465-f4c417660002"}],
   "device_id": "",
   "device_owner": "",
   "binding:host_id": "ubuntu",
   "binding:vnic_type": "normal",
   "binding:vif_type": "ovs",
   "binding:vif_details": [{"port_filter": false}]
   }
 }

neutron_test_l3vpn = {
 "input": {
   "l3vpn": [{
      "id": "4ae8cd92-48ca-49b5-94e1-b2921a260003",
      "name": "vpn",
      "route-distinguisher": ['100:1'],
      "export-RT": ['100:1'],
      "import-RT": ['100:1'],
      "tenant-id": tenantId
      }]
   }
 }

net_ass_diss_conf_1 = {
 "input": {
   "vpn-id": "4ae8cd92-48ca-49b5-94e1-b2921a260003",
   "network-id": ["12809f83-ccdf-422c-a20a-4ddae0710001"]
   }
 }

net_ass_diss_conf_2 = {
   "input": {
      "vpn-id": "4ae8cd92-48ca-49b5-94e1-b2921a260003",
      "network-id": ["12809f83-ccdf-422c-a20a-4ddae0710002"]
   }
 }

get_delete_l3vpn = {
 "input": {
   "id": ["4ae8cd92-48ca-49b5-94e1-b2921a260003"]
   }
 }

ass_diss = {
 "input": {
   "vpn-id": "4ae8cd92-48ca-49b5-94e1-b2921a260003",
   "network-id": [
      "12809f83-ccdf-422c-a20a-4ddae0710001",
      "12809f83-ccdf-422c-a20a-4ddae0710002"]
   }
 }

get_deletel3vpn = {
 "input": {
   "id": ["4ae8cd92-48ca-49b5-94e1-b2921a260003"]
   }
 }

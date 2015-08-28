import json


def get_variables(mininet1_ip, mininet2_ip):
    vpn_instances = {
        "vpn-instance": [
            {
                "description": "Test VPN Instance 1",
                "vpn-instance-name": "testVpn1",
                "ipv4-family": {
                    "route-distinguisher": "100:1",
                    "export-route-policy": "300:1",
                    "import-route-policy": "200:1",
                    "apply-label": {
                        "apply-label-per-route": "true"
                    }
                }
            },
            {
                "description": "Test VPN Instance 2",
                "vpn-instance-name": "testVpn2",
                "ipv4-family": {
                    "route-distinguisher": "400:1",
                    "export-route-policy": "500:1",
                    "import-route-policy": "600:1",
                    "apply-label": {
                        "apply-label-per-route": "true"
                    }
                }
            }
        ]
    }
    ietf_interfaces = {
        "interface": [
            {
                "name": "s1-eth1",
                "type": "iana-if-type:l2vlan",
                "odl-interface:of-port-id": "openflow:1:1",
                "enabled": "true"
            },
            {
                "name": "s1-eth2",
                "type": "iana-if-type:l2vlan",
                "odl-interface:of-port-id": "openflow:1:2",
                "enabled": "true"
            },
            {
                "name": "s2-eth1",
                "type": "iana-if-type:l2vlan",
                "odl-interface:of-port-id": "openflow:2:1",
                "enabled": "true"
            },
            {
                "name": "s2-eth2",
                "type": "iana-if-type:l2vlan",
                "odl-interface:of-port-id": "openflow:2:2",
                "enabled": "true"
            },
            {
                "enabled": "true",
                "odl-interface:of-port-id": "openflow:1:3",
                "description": "VM Port mpls",
                "name": "s1-gre1",
                "type": "odl-interface:l3tunnel",
                "odl-interface:tunnel-type": "odl-interface:tunnel-type-gre",
                "odl-interface:local-ip": mininet1_ip,
                "odl-interface:remote-ip": mininet2_ip
            },
            {
                "enabled": "true",
                "odl-interface:of-port-id": "openflow:2:3",
                "description": "VM Port mpls",
                "name": "s2-gre1",
                "type": "odl-interface:l3tunnel",
                "odl-interface:tunnel-type": "odl-interface:tunnel-type-gre",
                "odl-interface:local-ip": mininet2_ip,
                "odl-interface:remote-ip": mininet1_ip
            }
        ]
    }
    vpn_interfaces = {
        "vpn-interface": [
            {
                "odl-l3vpn:adjacency": [
                    {
                        "odl-l3vpn:ip_address": "10.0.0.1",
                        "odl-l3vpn:mac_address": "00:00:00:00:00:01"
                    }
                ],
                "vpn-instance-name": "testVpn1",
                "name": "s1-eth1"
            },
            {
                "odl-l3vpn:adjacency": [
                    {
                        "odl-l3vpn:ip_address": "10.0.0.2",
                        "odl-l3vpn:mac_address": "00:00:00:00:00:02"
                    }
                ],
                "vpn-instance-name": "testVpn2",
                "name": "s1-eth2"
            },
            {
                "odl-l3vpn:adjacency": [
                    {
                        "odl-l3vpn:ip_address": "10.0.0.3",
                        "odl-l3vpn:mac_address": "00:00:00:00:00:03"
                    }
                ],
                "vpn-instance-name": "testVpn1",
                "name": "s2-eth1"
            },
            {
                "odl-l3vpn:adjacency": [
                    {
                        "odl-l3vpn:ip_address": "10.0.0.4",
                        "odl-l3vpn:mac_address": "00:00:00:00:00:04"
                    }
                ],
                "vpn-instance-name": "testVpn2",
                "name": "s2-eth2"
            }
        ]
    }
    vpn_inst_data = json.dumps(vpn_instances)
    ietf_int_data = json.dumps(ietf_interfaces)
    vpn_int_data = json.dumps(vpn_interfaces)
    variables = {'vpn_instances': vpn_inst_data,
                 'ietf_interfaces': ietf_int_data,
                 'vpn_interfaces': vpn_int_data}
    return variables

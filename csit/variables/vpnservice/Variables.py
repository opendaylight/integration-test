def get_variables():
    variables = {}
    vpn_instance = {
        "vpn-instance": [
            {
                "description": "Test VPN Instance 1",
                "vpn-instance-name": "testVpn1",
                "ipv4-family": {
                    "route-distinguisher": "1000:1",
                    "export-route-policy": "3000:1,4000:1",
                    "import-route-policy": "1000:1,2000:1",
                    "apply-label": {
                        "apply-label-per-route": "true"
                    }
                }
            }
        ]
    }
    vm_interface = {
        "interface": [
            {
                "name": "s1-eth1",
                "type": "iana-if-type:l2vlan",
                "odl-interface:of-port-id": "openflow:1:1",
                "enabled": "true"
            }
        ]
    }
    vm_vpninterface = {
        "vpn-interface": [
            {
                "odl-l3vpn:adjacency": [
                    {
                        "odl-l3vpn:ip_address": "10.0.0.1",
                        "odl-l3vpn:mac_address": "12:f8:57:a8:b9:a1"
                    }
                ],
                "vpn-instance-name": "testVpn1",
                "name": "s1-eth1"
            }
        ]
    }
    bgp_router = {
        "bgp-router": {
            "local-as-identifier": "10.10.10.10",
            "local-as-number": 108
        }
    }
    bgp_neighbor = {
        "bgp-neighbor": [
            {
                "as-number": 105,
                "ip-address": "169.144.42.168"
            }
        ]
    }
    variables = {'vpn_instance': vpn_instance,
                 'vm_interface': vm_interface,
                 'vm_vpninterface': vm_vpninterface,
                 'bgp_router': bgp_router,
                 'bgp_neighbor': bgp_neighbor}
    return variables

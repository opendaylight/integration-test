*** Settings ***
Documentation     Variables for Netvirt Test Suites

*** Variables ***
@{legacy_feature_list}    odl-vtn-manager-neutron    odl-ovsdb-openstack
@{NETWORKS}       NETWORK1    NETWORK2    NETWORK3
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3
@{SUBNET_CIDR}    10.10.10.0/24    10.20.20.0/24    10.30.30.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6
@{VM_INSTANCES_NET1}    VM1    VM2
@{VM_INSTANCES_NET2}    VM3    VM4
@{VM_INSTANCES_NET3}    VM5    VM6
${ROUTERS}        ROUTER_1
${RESP_CODE}      200
${RESP_ERROR_CODE}    400
${MAC_REGEX}      ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})
${PING_REGEXP}    , 0% packet loss
${NO_PING_REGEXP}    , 100% packet loss
# Values passed for ARP_Learning
@{EXTRA_NW_IP}    192.168.10.110    192.168.20.110
${FIB_ENTRY_2}    192.168.10.110
${FIB_ENTRY_4}    192.168.20.110
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 192.168.10.110 192.168.10.110
${RPING_MIP_IP_2}    sudo arping -I eth0:1 -c 5 -b -s 192.168.20.110 192.168.20.110
${RPING_EXP_STR}    broadcast
# Values passed for BFD Tunnel monitoring
${TUNNEL_MONITOR_ON}    Tunnel Monitoring (for VXLAN tunnels): On
${TUNNEL_MONITOR_OFF}    Tunnel Monitoring (for VXLAN tunnels): Off
${MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels)
${INTERVAL_1000}    1000
${TMI_1000}       :1000
${TMI_2000}       :2000
${TMI_20000}      :20000
${TMI_30000}      :30000
${TMI_31000}      :31000
${TMI_50}         :50
${TMI_0}          :0
${TMI_NEG}        :-100
${BFD}            bfd
${LLDP}           lldp
${TEP_SHOW}       tep:show
${TEP_SHOW_STATE}    tep:show-state
${VXLAN_SHOW}     vxlan:show
${MONITOR_INTERVAL_NEW}    ${CONFIG_API}/itm-config:tunnel-monitor-interval/
${INTERVAL_50}    {"tunnel-monitor-interval":{"interval":50}}
${INTERVAL_0}     {"tunnel-monitor-interval":{"interval":0}}
${INTERVAL_NEG}    {"tunnel-monitor-interval":{"interval":-100}}
${INTERVAL_31000}    {"tunnel-monitor-interval":{"interval":31000}}
#ODL Rest URLs
${NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${PORT_URL}       ${CONFIG_API}/neutron:neutron/ports/
${TUNNEL_MONITOR_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
${MONITOR_INTERVAL_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
${TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/
${LEARNT_VIP}     ${OPERATIONAL_API}/odl-l3vpn:learnt-vpn-vip-to-port-data/
${DISPATCHER_TABLE}    17
${GWMAC_TABLE}    19
${ARP_RESPONSE_TABLE}    81
${L3_TABLE}       21
${ELAN_SMACTABLE}    50
${ELAN_DMACTABLE}    51
${ELAN_UNKNOWNMACTABLE}    52

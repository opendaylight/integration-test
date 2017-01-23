*** Settings ***
Documentation     Variables for Netvirt Test Suites

*** Variables ***
@{NETWORKS}       NET50    NET60    NET70
@{SUBNETS}        SUBNET50    SUBNET60    SUBNET70
@{SUBNET_CIDR}    50.1.1.0/24    60.1.1.0/24    70.1.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6
@{VM_INSTANCES_NET1}    VM1    VM2
@{VM_INSTANCES_NET2}    VM3    VM4
@{VM_INSTANCES_NET3}    VM5    VM6
@{ROUTERS}        ROUTER_1    ROUTER_2
${CONFIG_API}     /restconf/config
${OPERATIONAL_API}    /restconf/operational
${RESP_CODE}      200
${RESP_ERROR_CODE}    400
${PING_REGEXP}    , 0% packet loss
${NO_PING_REGEXP}    , 100% packet loss
${MAC_REGEX}      ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})
# Values for L3VPN
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
${CREATE_RD}      ["2200:2"]
${CREATE_RD1}      ["2200:3"]    
${CREATE_EXPORT_RT}    ["2200:2","2200:3"]
${CREATE_IMPORT_RT}    ["2200:2","2200:3"]
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
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${TUNNEL_MONITOR_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
${MONITOR_INTERVAL_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
${TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/

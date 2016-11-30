*** Settings ***
Documentation     Variables for Vpnservice test suites

*** Variables ***
@{NETWORKS}       NET1    NET2
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    20.1.1.0/24    20.2.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4
@{VM_INSTANCES_NET1}    VM1    VM2
@{VM_INSTANCES_NET2}    VM3    VM4
@{ROUTERS}        ROUTER_1    ROUTER_2
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
${CREATE_RD}      ["2200:2"]
${CREATE_EXPORT_RT}    ["2200:2","8800:2"]
${CREATE_IMPORT_RT}    ["2200:2","8800:2"]
${CONFIG_API}     /restconf/config
${OPERATIONAL_API}    /restconf/operational
${RESP_CODE}      200
# Values passed for extra routes
@{EXTRA_NW_IP}    10.1.1.110
@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24
${EXT_RT1}        destination=40.1.1.0/24,nexthop=10.1.1.3
${EXT_RT2}        destination=50.1.1.0/24,nexthop=10.1.1.3
${RT_OPTIONS}     --routes type=dict list=true
${RT_CLEAR}       --routes action=clear
${MAC_REGEX}      ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})
# Values passed for ARP Request
${FIB_ENTRY_1}    10.1.1.3
${FIB_ENTRY_1}    10.1.1.110
${FIB_ENTRY_3}    10.1.1.4
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 10.1.1.110 10.1.1.110
${RPING_EXP_STR}    broadcast
# Values passed for BFD Tunnel monitoring
${TUNNEL_MONITOR_ON}    Tunnel Monitoring (for VXLAN tunnels): On
${TUNNEL_MONITOR_OFF}    Tunnel Monitoring (for VXLAN tunnels): Off
${MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 100
${INTERVAL_1000}    1000
${TMI_100}        :1000
${TMI_200}        :2000
${TMI_30000}      :30000
${TMI_50}         :50
${BFD}            bfd
${TUNNEL_MONITOR_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
${MONITOR_INTERVAL_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
${TEP_SHOW}       tep:show
${TEP_SHOW_STATE}    tep:show-state
${VXLAN_SHOW}     vxlan:show

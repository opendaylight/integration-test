*** Settings ***
Documentation     Variables for Netvirt Test Suites

*** Variables ***
# Exceptions for which we will not create a failure
@{legacy_feature_list}    odl-vtn-manager-neutron    odl-ovsdb-openstack
${CIRROS_stable/ocata}    cirros-0.3.4-x86_64-uec
${CIRROS_stable/pike}    cirros-0.3.5-x86_64-disk
${CIRROS_stable/queens}    cirros-0.3.5-x86_64-disk
${CIRROS_master}    cirros-0.3.5-x86_64-disk
${CONTAINERS}     False
@{DISPLAY_NAPT_CMD}    Safe_Issue_Command_On_Karaf_Console    display-napt-switches
@{DISPLAY_NAPT_CMD_CONTAINERS}    Utils.Run Command On Controller    ${ODL_SYSTEM_IP}    sudo docker exec -i opendaylight_api /opt/opendaylight/bin/client -u karaf display-napt-switches
${PRE_CLEAN_OPENSTACK_ALL}    False
${EXTERNAL_NET_NAME}    external-net
${EXTERNAL_SUBNET_NAME}    external-subnet
${EXTERNAL_GATEWAY}    10.10.10.250
${EXTERNAL_SUBNET}    10.10.10.0/24
${EXTERNAL_SUBNET_ALLOCATION_POOL}    start=10.10.10.2,end=10.10.10.249
${NET1_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:2::2,end=2001:db8:0:2:ffff:ffff:ffff:fffe
${NET2_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:3::2,end=2001:db8:0:3:ffff:ffff:ffff:fffe
${RESP_CODE}      200
${RESP_ERROR_CODE}    400
${MAC_REGEX}      ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})
${IP_REGEX}       (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])
${IP6_REGEX}      (2001:([0-9A-Fa-f]{0,4}:){1,6}([0-9A-Fa-f]{1,4}))
${IP6_SUBNET_CIDR_SUFFIX}    ::/64
${IP6_ADDR_SUFFIX}    (:[a-f0-9]{,4}){,4}
${PING_REGEXP}    , 0% packet loss
${NO_PING_REGEXP}    , 100% packet loss
# Values passed for extra routes
${RT_OPTIONS}     --route
${RT_CLEAR}       --no-route
${ARP_RESPONSE_REGEX}    arp,arp_op=2 actions=CONTROLLER:65535,resubmit\\(,${ELAN_BASETABLE}\\)
${ARP_REQUEST_REGEX}    arp,arp_op=1 actions=group:\\d+
${ARP_REQUEST_GROUP_REGEX}    actions=CONTROLLER:65535,bucket=actions=resubmit\\(,${ELAN_BASETABLE}\\),bucket=actions=resubmit\\(,${ARP_RESPONSE_TABLE}\\)
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
${ROUTER_URL}     ${CONFIG_API}/neutron:neutron/routers/
${FIB_ENTRY_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${VPN_IFACES_URL}    ${CONFIG_API}/l3vpn:vpn-interfaces/
${VPN_PORT_DATA_URL}    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
${TUNNEL_MONITOR_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
${MONITOR_INTERVAL_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
${TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/
${LEARNT_VIP}     ${OPERATIONAL_API}/odl-l3vpn:learnt-vpn-vip-to-port-data/
${DISPATCHER_TABLE}    17
${GWMAC_TABLE}    19
${ARP_CHECK_TABLE}    43
${ARP_RESPONSE_TABLE}    81
${IPV6_TABLE}     45
${L3_TABLE}       21
${ELAN_BASETABLE}    48
${ELAN_SMACTABLE}    50
${ELAN_DMACTABLE}    51
${ELAN_UNKNOWNMACTABLE}    52
${SECURITY_GROUP}    l3_ext_sg
${NETWORK}        internal-net
${SUBNET}         internal-subnet
${SUBNET_CIDR}    41.0.0.0/24
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${EXTERNAL_GATEWAY}    10.10.10.250
${EXTERNAL_PNF}    10.10.10.253
${EXTERNAL_SUBNET}    10.10.10.0/24
${EXTERNAL_SUBNET_ALLOCATION_POOL}    start=10.10.10.2,end=10.10.10.249
${EXTERNAL_INTERNET_ADDR}    10.9.9.9
${EXTERNAL_NET_NAME}    external-net
${EXTERNAL_SUBNET_NAME}    external-subnet

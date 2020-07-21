*** Settings ***
Documentation     Variables for Netvirt Test Suites

*** Variables ***
# Exceptions for which we will not create a failure
@{NETVIRT_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    ELAN    OVSDB
${CIRROS_stable/queens}    cirros-0.3.5-x86_64-disk
${CIRROS_stable/rocky}    cirros-0.3.5-x86_64-disk
${CIRROS_stable/stein}    cirros-0.4.0-x86_64-disk
${PASSWORD_CIRROS_stable/stein}    gocubsgo
${PASSWORD_CIRROS_stable/rocky}    cubswin:)
${PASSWORD_CIRROS_stable/queens}   cubswin:)
${CIRROS_master}    cirros-0.4.0-x86_64-disk
${DEFAULT_PING_COUNT}    3
${PRE_CLEAN_OPENSTACK_ALL}    False
${EXTERNAL_NET_NAME}    external-net
${EXTERNAL_SUBNET_NAME}    external-subnet
${INTEGRATION_BRIDGE}    br-int
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
${ARP_RESPONSE_REGEX_FLUORINE}    arp,arp_op=2 actions=resubmit\\(,${ARP_PUNT_TABLE}\\),resubmit\\(,${ARP_LEARN_TABLE}\\),resubmit\\(,${ELAN_BASETABLE}\\)
${ARP_PUNT_RESPONSE_REGEX}    arp actions=CONTROLLER:65535,learn
${ARP_REQUEST_REGEX}    arp,arp_op=1 actions=group:\\d+
${ARP_REQUEST_GROUP_REGEX}    actions=CONTROLLER:65535,bucket=actions=resubmit\\(,${ELAN_BASETABLE}\\),bucket=actions=resubmit\\(,${ARP_RESPONSE_TABLE}\\)
${ARP_REQUEST_GROUP_REGEX_FLUORINE}    actions=resubmit\\(,${ARP_RESPONSE_TABLE}\\)
${ARP_CHECK_TABLE}    43
${ARP_PUNT_TABLE}    195
${ARP_LEARN_TABLE}    196
${ARP_RESPONSE_TABLE}    81
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
${RUN_CONFIG}     show running-config
${MONITOR_INTERVAL_NEW}    ${CONFIG_API}/itm-config:tunnel-monitor-interval/
${INTERVAL_50}    {"tunnel-monitor-interval":{"interval":50}}
${INTERVAL_0}     {"tunnel-monitor-interval":{"interval":0}}
${INTERVAL_NEG}    {"tunnel-monitor-interval":{"interval":-100}}
${INTERVAL_31000}    {"tunnel-monitor-interval":{"interval":31000}}
#ODL Rest URLs
${NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks
${SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${PORT_URL}       ${CONFIG_API}/neutron:neutron/ports/
${ROUTER_URL}     ${CONFIG_API}/neutron:neutron/routers/
${FIB_ENTRY_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${VPN_IFACES_URL}    ${CONFIG_API}/l3vpn:vpn-interfaces/
${VPN_INST_IFACES_URL}    ${CONFIG_API}/l3vpn-instances-interfaces:vpn-interfaces/
${VPN_PORT_DATA_URL}    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
${TUNNEL_MONITOR_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
${MONITOR_INTERVAL_URL}    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
${TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/
${LEARNT_VIP}     ${OPERATIONAL_API}/odl-l3vpn:learnt-vpn-vip-to-port-data/
${DISPATCHER_TABLE}    17
${GWMAC_TABLE}    19
${L3_TABLE}       21
${L3_PUNT_TABLE}    22
${PDNAT_TABLE}    25
${PSNAT_TABLE}    26
${DNAT_TABLE}     27
${SNAT_TABLE}     28
${INTERNAL_TUNNEL_TABLE}    36
${IPV6_TABLE}     45
${SNAT_PUNT_TABLE}    46
${ELAN_BASETABLE}    48
${ELAN_SMACTABLE}    50
${ELAN_DMACTABLE}    51
${ELAN_UNKNOWNMACTABLE}    52
${INGRESS_ACL_REMOTE_ACL_TABLE}    211
${EGRESS_ACL_TABLE}    240
${VLAN_INTERFACE_INGRESS_TABLE}    0
${EGRESS_LPORT_DISPATCHER_TABLE}    220
${EGRESS_LEARN_ACL_FILTER_TABLE}    244
@{DEFAULT_FLOW_TABLES}    18    19    20    22    23    24    43
...               45    48    50    51    60    80    81
...               90    210    211    212    213    214    215
...               216    217    239    240    241    242    243
...               244    245    246    247
${TRANSPORT_ZONE_ENDPOINT_URL}    ${CONFIG_API}/itm:transport-zones/transport-zone
${GENIUS_VAR_DIR}    ${CURDIR}/../../variables/genius
${TEP_NOT_HOSTED_ZONE_URL}    ${OPERATIONAL_API}/itm:not-hosted-transport-zones

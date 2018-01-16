""" Variables specific to BGP VPNs """
# bgp configuration/installation specific variables 



# bgp neighborship variables 





# bgp vpn variables 



# bgp route variables 


@{NETWORKS}       bgp_net_1    bgp_net_2    bgp_net_3    bgp_net_4
@{SUBNETS}        bgp_sub_1    bgp_sub_2    bgp_sub_3    bgp_sub_4
@{SUBNET_CIDR}    101.1.1.0/8    102.1.1.0/16    103.1.1.0/24    104.1.1.0/24
@{PORTS}          bgp_port_101    bgp_port_102    bgp_port_103    bgp_port_104
@{VM_NAMES}       bgp_vm_101    bgp_vm_102    bgp_vm_103    bgp_vm_104
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112
@{RD_LIST}        ["2200:2"]    ["2300:2"]
@{VPN_NAMES}      bgp_vpn_101    bgp_vpn_102
${LOOPBACK_IP}    5.5.5.2
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${AS_ID}          500
${DCGW_RD}        2200:2
${SECURITY_GROUP_BGP}    sg_bgp
${ODL_IP}         192.168.122.123
${ROUTERID}       ${ODL_SYSTEM_IP}
${DCGW_ROUTERID}    ${DCGW_SYSTEM_IP}
${addr_family}    vpnv4 unicast
${BGP_PORT}       179    # bgp port use for communication with DC-Gwy BGP
${NETSTAT_DCGWYBGP_PORT_REGEX}    :${BGP_PORT}\\s+\(.*\)\\s+ESTABLISHED\\s+(.*)bgpd    # check for established state
${NETSTAT}        sudo netstat -napt 2> /dev/null    # netstat command
${BGPD_PROCESS_NAME}    bgpd    # bgpd process name
${KILL_BGPD}      sudo pkill -TERM ${GREP_BGPD}    # grep bgpd process name and kill the same
${ZRPCD_PROCESS_NAME}    zrpcd    # zrpc process name
${KILL_ZRPCD}     sudo \ pkill -TERM ${GREP_ZRPCD}    # kill zrpcd process
${GREP_BGPD}      pgrep ${BGPD_PROCESS_NAME}    # verify bgpd process is present
${GREP_ZRPCD}     pgrep ${ZRPCD_PROCESS_NAME}    # grep zrpc process name
${KARAF_SHELL_PORT}    8101    # karaf shell port
${FIB_SHOW}       fib-show    # fib show command
${BGP_FIB_ENTRIES_PRESENT_REGEX}    [1-9]\d*
${NO_BGP_FIB_ENTRIES_COUNT}    0    # 0 fib entries
${BGP_GR_STALEPATH_TIME}    90
${BGP_ORIGIN_TYPE}    \\s+b\\s+
${BGP_HOLD_TIME}    25
${BGP_KEEPALIVE_TIME}    5
${DELAY_START_BGPD_SECONDS}    10
${BGP_IPTABLES_UPDATE_TIME}    3
${NETSTAT_BGPPORT_ESTABLISHED}    sudo netstat -napt 2> /dev/null | grep ${BGP_PORT} | grep ESTABLISHED

#parameterization of bgp commands 


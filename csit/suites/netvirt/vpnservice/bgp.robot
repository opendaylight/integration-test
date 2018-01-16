*** Settings ***
Documentation     Test suite to validate BGP vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BGP Vpnservice Suite Setup
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing    #Suite Teardown    BGP Vpnservice Suite Teardown
Library           OperatingSystem    #Test Teardown    OpenStackOperations.Get Test Teardown Debugs
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/WaitForFailure.robot    # WaitForFailure

*** Variables ***
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

*** Test Cases ***
Create BGP Config On ODL
    [Documentation]    Create BGP Config on ODL controller
    \    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ROUTERID}
    \    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP Config on DCGW
    \    BgpOperations.Start BGP Processes On DCGW    ${DCGW_SYSTEM_IP}
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_ROUTERID}    ${ODL_IP}    ${addr_family}
    BgpOperations.Configure VPN On DCGW   ${dcgw_ip}    ${as_id}    ${vrf_name}    ${rd}    ${irt}    ${ert} 
    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    BgpOperations.Execute Show Command On DCGW    ${DCGW_SYSTEM_IP}    show running-config
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${ODL_SYSTEM_IP}
    #    BuiltIn.Should Contain    ${output1}    ${LOOPBACK_IP}

Verify BGP Neighbor Status
    [Documentation]    Verify BGP Neighborship status established
    #    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    15s
    BgpOperations.Verify BGP Neighbor Status On DCGW    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    #    BuiltIn.Log    ${output}
    ${output1} =    BgpOperations.Execute Show Command On DCGW    ${DCGW_SYSTEM_IP}    show ip bgp neighbors
    BuiltIn.Log    ${output1}
    BuiltIn.Should Contain    ${output1}    ${LOOPBACK_IP}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Verify Routes Exchange Between ODL And DCGW
    [Documentation]    Verify routes exchange between ODL and DCGW
    ${fib_values} =    BuiltIn.Create List    ${LOOPBACK_IP}    @{VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Utils.Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${DCGW_RD}/    ${fib_values}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Verify Routes On Quagga    ${DCGW_SYSTEM_IP}    ${DCGW_RD}    ${fib_values}



Restart BGP Process
    [Documentation]    Delete BGP Configuration on DCGW
    On ODL
    ${output} =    BgpOperations.Restart bgp Processes On ODL    ${ODL_SYSTEM_IP}
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Restart BGP Process
    [Documentation]    Delete BGP Configuration on DCGW
    On DCGW
    ${output} =    BgpOperations.Restart BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
    BuiltIn.Log    ${output}
    BuiltIn.Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

Restart BGP Neighbor On DCGW
    [Documentation]    Delete BGP Configuration on DCGW
    ${output} =    BgpOperations.Restart BGP Config On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}
    BuiltIn.Log    ${output}
    Verify Routes Exchange Between ODL And DCGW
    #    BuiltIn.Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

Clear BGP Neighbor On DCGW
    [Documentation]    Delete BGP Configuration on DCGW
    ${output} =    BgpOperations.Clear BGP Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${ODL_IP}
    BuiltIn.Log    ${output}
    #    BuiltIn.Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

Admin Down BGP Neighbor On DCGW
    [Documentation]    Admin Down of BGP Neighbor on DCGW
    ${output} =    BgpOperations.Admin Down BGP Neighbor on DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${ODL_IP}    ${addr_family}
    BuiltIn.Log    ${output}
    #    BuiltIn.Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

Admin UP BGP Neighbor On DCGW
    [Documentation]    Admin UP of BGP Neighbor on DCGW
    ${output} =    BgpOperations.Admin UP BGP Neighbor on DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${ODL_IP}    ${addr_family}
    BuiltIn.Log    ${output}
    #    BuiltIn.Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

Delete External Tunnel Endpoint
    [Documentation]    Delete external tunnel endpoint
    BgpOperations.Delete External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Not Contain    ${output}    ${DCGW_SYSTEM_IP}

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    BgpOperations.Delete BGP Configuration On ODL    session
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    BuiltIn.Should Not Contain    ${output}    ${DCGW_SYSTEM_IP}
    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/

Delete BGP Config On DCGW
    [Documentation]    Delete BGP Configuration on DCGW
    ${output} =    BgpOperations.Delete BGP Config On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}
    BuiltIn.Log    ${output}
    BuiltIn.Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

Disassociate L3VPN From Router
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}    ${devstack_conn_id}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}    ${devstack_conn_id}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${INTERFACE}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    BuiltIn.Should Not Contain    ${interface_output}    ${subnet_id}
    Delete Router    ${ROUTER}
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Should Not Contain    ${router_output}    ${ROUTER}
    @{router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}






Verify Routes Retained until BGP HOLD iptables Timer
    [Documentation]    Verify routes exchange between ODL and DCGW
    [Setup]
    Comment    Bgp Operations.Restart thrift Processes On ODL    ${controller}
    Sleep    ${DELAY_START_BGPD_SECONDS}    #to let the configuration go to qthriftd and start bgpd
    ${fib_before_stopbgp} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    log    ${fib_before_stopbgp}
    Should Match Regexp    ${fib_before_stopbgp}    ${BGP_FIB_ENTRIES_PRESENT_REGEX}
    ${timestamp_before_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_before_kill}
    ${output} =    BgpOperations.Check for BGP Processes On DCGW    ${dcgw_ip}
    log    ${output}
    ${output} =    BgpOperations.iptables disable BGP port communication    ${dcgw_ip}
    log    ${output}
    ${output} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    log    ${output}
    ${BGP_HOLD_ROUTES_TIME}=    BuiltIn.Evaluate    ${BGP_HOLD_TIME}-${BGP_KEEPALIVE_TIME}-${BGP_IPTABLES_UPDATE_TIME}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${BGP_HOLD_ROUTES_TIME}    1s    BgpOperations.is ODL fib contains routes from DC-Gwy    ${BGP_ORIGIN_TYPE}
    Sleep    ${BGP_KEEPALIVE_TIME}
    Sleep    ${BGP_IPTABLES_UPDATE_TIME}
    ${fib_after_stopbgp_holdtime} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    Should not Match Regexp    ${fib_after_stopbgp_holdtime}    ${BGP_ORIGIN_TYPE}
    ${output} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    log    ${output}
    ${timestamp_after_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_after_kill}
    ${routes_retained_sec} =    DateTime.Subtract Date From Date    ${timestamp_after_kill}    ${timestamp_before_kill}
    log    ${routes_retained_sec}
    ${output} =    BgpOperations.iptables enable BGP port communication    ${dcgw_ip}
    #    BgpOperations.iptables enable BGP port communication    shall be made as part of exit test case criteria
    [Teardown]    BgpOperations.iptables enable BGP port communication    ${dcgw_ip}

Verify Routes intact by doing stop BGP and start BGP with HOLD Timer
    [Documentation]    Verify routes exchange between ODL and DCGW
    [Setup]
    Comment    Bgp Operations.Restart thrift Processes On ODL    ${controller}
    Sleep    60s    #to let the configuration go to qthriftd and start bgpd
    ${output} =    BgpOperations.Check for BGP Processes On DCGW    ${dcgw_ip}
    log    ${output}
    ${fib_before_aclrule_enabled} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    log    ${fib_before_aclrule_enabled}
    Should Match Regexp    ${fib_before_aclrule_enabled}    ${BGP_ORIGIN_TYPE}
    ${output} =    BgpOperations.iptables disable BGP port communication    ${dcgw_ip}
    log    ${output}
    ${BGP_2KA_EXPIRYT_TIME}=    BuiltIn.Evaluate    ${BGP_KEEPALIVE_TIME} + ${BGP_KEEPALIVE_TIME}
    Log    ${BGP_2KA_EXPIRYT_TIME}
    ${dcgw_conn_id} =    Open_Connection_To_Tools_System    ${dcgw_ip}
    Log    ${dcgw_conn_id}
    Comment    ${netstat_bgp_established_before_acl_rules}=    Exec Command    ${dcgw_conn_id}    ${NETSTAT_BGPPORT_ESTABLISHED}
    Comment    Log    ${netstat_bgp_established_before_acl_rules}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${BGP_2KA_EXPIRYT_TIME}    1s    BgpOperations.is ODL fib contains routes from DC-Gwy    ${BGP_ORIGIN_TYPE}
    ${output} =    BgpOperations.iptables enable BGP port communication    ${dcgw_ip}
    Sleep    ${BGP_KEEPALIVE_TIME}
    Comment    ${netstat_bgp_established_after_acl_rules}=    Exec Command    ${dcgw_conn_id}    ${NETSTAT_BGPPORT_ESTABLISHED}
    Comment    Log    ${netstat_bgp_established_after_acl_rules}
    ${fib_after_aclrule_disabled} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    Should Match Regexp    ${fib_after_aclrule_disabled}    ${BGP_ORIGIN_TYPE}
    log    ${fib_after_aclrule_disabled}
    Comment    Should Match    ${netstat_bgp_established_before_acl_rules}    ${netstat_bgp_established_after_acl_rules}
    Should Match    ${fib_before_aclrule_enabled}    ${fib_after_aclrule_disabled}
    #    BgpOperations.iptables enable BGP port communication    shall be made as part of exit test case criteria
    [Teardown]    BgpOperations.iptables enable BGP port communication    ${dcgw_ip}

Verify Routes Retained until BGP GR Stale Path Timer
    [Documentation]    Verify routes exchange between ODL and DCGW
    [Setup]
    Comment    Bgp Operations.Restart thrift Processes On ODL    ${controller}
    Sleep    ${DELAY_START_BGPD_SECONDS}    #to let the configuration go to qthriftd and start bgpd
    ${fib_before_stopbgp} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    log    ${fib_before_stopbgp}
    Should Match Regexp    ${fib_before_stopbgp}    ${BGP_ORIGIN_TYPE}
    ${timestamp_before_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_before_kill}
    ${output} =    BgpOperations.Check for BGP Processes On DCGW    ${dcgw_ip}
    log    ${output}
    ${output} =    BgpOperations.Stop BGP Processes On DCGW    ${dcgw_ip}    KILL
    log    ${output}
    ${output} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    log    ${output}
    ${BGP_WAIT_GR_STALEPATH_TIME} =    BuiltIn.Evaluate    ${BGP_GR_STALEPATH_TIME}-${BGP_KEEPALIVE_TIME} - 2
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${BGP_WAIT_GR_STALEPATH_TIME}    1s    BgpOperations.is ODL fib contains routes from DC-Gwy    ${BGP_ORIGIN_TYPE}
    Sleep    12
    ${fib_after_stopbgp_grstalepathtime} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    Should not Match Regexp    ${fib_after_stopbgp_grstalepathtime}    ${BGP_ORIGIN_TYPE}
    ${output} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    log    ${output}
    ${timestamp_after_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_after_kill}
    ${routes_retained_sec} =    DateTime.Subtract Date From Date    ${timestamp_after_kill}    ${timestamp_before_kill}
    log    ${routes_retained_sec}
    [Teardown]    BgpOperations.Start BGP Processes On DCGW    ${dcgw_ip}

Verify Routes intact by doing stop BGP and start BGP with GR stale path timer
    [Documentation]    Verify routes exchange between ODL and DCGW
    [Setup]
    Sleep    100s    #to let the configuration go to qthriftd and start bgpd
    ${output} =    BgpOperations.Check for BGP Processes On DCGW    ${dcgw_ip}
    log    ${output}
    ${fib_before_stopbgp} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    log    ${fib_before_stopbgp}
    Should Match Regexp    ${fib_before_stopbgp}    ${BGP_ORIGIN_TYPE}
    ${output} =    BgpOperations.Stop BGP Processes On DCGW    ${dcgw_ip}    KILL
    log    ${output}
    ${dcgw_conn_id} =    Open_Connection_To_Tools_System    ${dcgw_ip}
    Log    ${dcgw_conn_id}
    ${BGP_2KA_EXPIRYT_TIME}=    BuiltIn.Evaluate    ${BGP_KEEPALIVE_TIME} + ${BGP_KEEPALIVE_TIME}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${BGP_2KA_EXPIRYT_TIME}    1s    BgpOperations.is ODL fib contains routes from DC-Gwy    ${BGP_ORIGIN_TYPE}
    ${output} =    BgpOperations.Start BGP Processes On DCGW    ${dcgw_ip}
    log    ${output}
    ${fib_after_stopbgp}=    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${KARAF_SHELL_PORT}
    should match    ${fib_after_stopbgp}    ${fib_before_stopbgp}
    [Teardown]

Verify Routes Retained by stop BGP and start BGP before HOLD Down Timer
    [Documentation]    Verify routes exchange between ODL and DCGW
    [Setup]
    ${fib_before_stopbgp} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${karaf_port}
    log    ${fib_before_stopbgp}
    Should Match Regexp    ${fib_before_stopbgp}    ${BGP_FIB_ENTRIES_PRESENT_REGEX}
    ${timestamp_before_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_before_kill}
    ${output} =    BgpOperations.Check for BGP Processes On DCGW    ${dcgw_ip}
    log    ${output}
    ${output} =    BgpOperations.Restart BGP Config On DCGW    ${dcgw_ip}    ${AS_ID}
    log    ${output}
    Wait Until Keyword Succeeds    1s    1s    Verify Strings In Command Output    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    " b"
    ${timestamp_after_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_after_kill}
    ${routes_retained_sec} =    DateTime.Subtract Date From Date    ${timestamp_after_kill}    ${timestamp_before_kill}
    log    ${routes_retained_sec}
    Should Be Equal As Numbers    ${routes_retained_sec}    ${hold_down_time_sec}

Verify Routes Retained by stop BGP and start BGP before GR StalePath Timer
    [Documentation]    Verify routes exchange between ODL and DCGW
    [Setup]
    ${fib_before_stopbgp} =    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    ${controller}    ${karaf_port}
    log    ${fib_before_stopbgp}
    Should Match Regexp    ${fib_before_stopbgp}    ${BGP_FIB_ENTRIES_PRESENT_REGEX}
    ${timestamp_before_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_before_kill}
    ${output} =    BgpOperations.Check for BGP Processes On DCGW    ${dcgw_ip}
    log    ${output}
    ${output} =    BgpOperations.Restart BGP Processes On DCGW using SIGTERM    ${dcgw_ip}
    log    ${output}
    Wait Until Keyword Succeeds    1s    1s    Verify Strings In Command Output    Issue_Command_On_Karaf_Console    ${FIB_SHOW}    " b"
    ${timestamp_after_kill} =    DateTime.Get Current Date    result_format=timestamp
    log    ${timestamp_after_kill}
    ${routes_retained_sec} =    DateTime.Subtract Date From Date    ${timestamp_after_kill}    ${timestamp_before_kill}
    log    ${routes_retained_sec}
    Should Be Equal As Numbers    ${routes_retained_sec}    ${hold_down_time_sec}

*** Keywords ***
BGP Vpnservice Suite Setup
    [Documentation]    Entering into BGP VPN service suite setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    #    DevstackUtils.Devstack Suite Setup
    #    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP_BGP}
    #    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    #    BgpOperations.Start BGP Processes On DCGW    ${DCGW_SYSTEM_IP}
    #    BgpOperations.Show Quagga Configuration On ODL    ${ODL_SYSTEM_IP}    ${DCGW_RD}
    #    Create Basic Configuartion for BGP VPNservice Suite

BGP Vpnservice Suite Teardown
    Delete Basic Configuartion for BGP VPNservice Suite
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP_BGP}
    SSHLibrary.Close All Connections

Create Basic Configuartion for BGP VPNservice Suite
    [Documentation]    Create basic configuration for BGP VPNservice suite
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    ${length} =    BuiltIn.Get Length    ${SUBNETS}
    : FOR    ${idx}    IN RANGE    ${length}
    \    OpenStackOperations.Create SubNet    ${NETWORKS[${idx}]}    ${SUBNETS[${idx}]}    @{SUBNET_CIDR}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    : FOR    ${network}    ${port}    IN ZIP    ${NETWORKS}    ${PORTS}
    \    OpenStackOperations.Create Port    ${network}    ${port}    sg=${SECURITY_GROUP_BGP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PORTS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{VM_NAMES}[0]    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP_BGP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{VM_NAMES}[1]    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP_BGP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{VM_NAMES}[2]    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP_BGP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{VM_NAMES}[3]    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP_BGP}
    @{VM_IPS}    ${DHCP_IPS} =    OpenStackOperations.Get VM IPs    @{VM_NAMES}
    BuiltIn.Set Suite Variable    @{VM_IPS}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Should Not Contain    ${DHCP_IPS}    None
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RD_LIST}[0]    exportrt=@{RD_LIST}[0]    importrt=@{RD_LIST}[0]    tenantid=${tenant_id}
    : FOR    ${network}    IN    @{NETWORKS}
    \    ${network_id} =    Get Net Id    ${network}    ${devstack_conn_id}
    \    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Log    ${resp}

Delete Basic Configuartion for BGP VPNservice Suite
    [Documentation]    Delete basic configuration for BGP Vpnservice suite
    : FOR    ${network}    IN    @{NETWORKS}
    \    ${network_id} =    OpenStackOperations.Get Net Id    ${network}    ${devstack_conn_id}
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    : FOR    ${vm}    IN    @{VM_NAMES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Delete Port    ${port}
    : FOR    ${subnet}    IN    @{SUBNETS}
    \    OpenStackOperations.Delete SubNet    ${subnet}
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}

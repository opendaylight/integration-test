*** Settings ***
Documentation     Test suite for ARP Request. More test cases to be added in subsequent patches.
Suite Setup       BuiltIn.Run Keywords    DevstackUtils.Devstack Suite Setup
...               AND    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    Create Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keyword If Test Failed    Get OvsDebugInfo
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/netvirt/Variables.robot
Variables         ../../../variables/Variables.py

*** Variables ***
#${PING_REGEXP}    , 0% packet loss
#${VAR_BASE}      ${CURDIR}/../../../variables/netvirt
@{EXTRA_NW_IP}    50.1.1.110    60.1.1.110
${FIB_ENTRY_1}    50.1.1.3
${FIB_ENTRY_2}    50.1.1.110
${FIB_ENTRY_3}    50.1.1.4
${FIB_ENTRY_4}    60.1.1.110
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 50.1.1.110 50.1.1.110
${RPING_MIP_IP_2}    sudo arping -I eth0:1 -c 5 -b -s 60.1.1.110 60.1.1.110
${RPING_EXP_STR}    broadcast
#${FIB_ENTRY_VM11_REGEX}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#${FIB_ENTRY_VM21_REGEX}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#${FIB_ENTRY_MIP_REGEX_DPN2}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#${FIB_ENTRY_MIP_REGEX_DPN1}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
${OTHER_IP}       50.1.1.8
${SUBNET1_IP}     50.1.1.1
${SUBNET2_IP}     60.1.1.1
${RD11}           2200:3
${BGP_PROMPT}       #
${DCGW_PROMPT}      \>
${VAR_BASE_BGP}     ${CURDIR}/../../../variables/bgpfunctional
${LOOPBACK_IP}      5.5.5.2
${DCGW_SYSTEM_IP}     ${TOOLS_SYSTEM_1_IP}
${AS_ID}            500

*** Test Cases ***
TC01 Verify GARP
    [Documentation]    Test Case 1
    Log    Validate the Flows on DPNs
    Wait Until Keyword Succeeds    10s    1s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    10s    1s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    ${output}=    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32".*"nextHopAddressList\\":\\["\\"${OS_COMPUTE_2_IP}\\"\\"]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
     ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32".*"nextHopAddressList\\":\\["\\"${OS_COMPUTE_1_IP}\\"\\"]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    Log    Checking the RX Packets Count on VM2 before ARP Broadcast
    ${rx_packet1_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig eth0
    Log    ${rx_packet1_before}
    Log    Checking the RX Packets Count on VM1 before ARP Broadcast
    ${rx_packet0_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0
    Log    ${rx_packet0_before}
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    20
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${RPING_MIP_IP}
    Should Contain    ${output}    broadcast
    Should Contain    ${output}    Received 0 reply
    Log    Validate the Flows on DPNs
    Log    Checking the RX Packets Count on VM2 after ARP Broadcast
    ${rx_packet1_after} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig eth0
    Log    ${rx_packet1_after}
    Log    Checking the RX Packets Count on VM1 before ARP Broadcast
    ${rx_packet0_after} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0
    Log    ${rx_packet0_after}
    Should Not Be Equal    ${rx_packet0_before}    ${rx_packet0_after}
    Should Not Be Equal    ${rx_packet1_before}    ${rx_packet1_after}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    Checking MAC-IP table in Config DS via REST
    ${output}=    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    Wait Until Keyword Succeeds    5s    1s    Get MAC IP

TC02 Verify MIP migration
    [Documentation]    Test Case 2
    Log    Validate the Flows on DPNs
    Wait Until Keyword Succeeds    10s    1s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    10s    1s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    Log    Bring down the Sub Interface on DPN2
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Not Contain    ${output}    eth0:1
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    Should Contain    ${output}    eth0:1
    Log    Verify VM1 has MIP
    ${rx_packet1_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0:1
    Log    ${rx_packet1_before}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    Should Contain    ${output}    broadcast
    Log    Generating the ARP requests by pinging
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping 50.1.1.110 -c 5
    Should Contain    ${output}    ${PING_REGEXP}
    Log    Validate the FIB entries in Controller
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    Wait Until Keyword Succeeds    5s    1s    Get MAC IP
    Log    Removing the created sub-interface
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${UNCONFIG_EXTRA_ROUTE_IP1}

TC03 Verify ping to subnet gateway
    Log    Bring the Sub Interface on DPN2
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Contain    ${output}    eth0:1
    Log    Verify VM1 has MIP
    ${rx_packet1_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig eth0:1
    Log    ${rx_packet1_before}
    Log    Generate ARP request
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    Log    Generate ARP from target VM1 by arping to the subnet gateway IP. ( ping to subnet gw ip network )
    ${ARP_TO_SUBNET}=    Catenate    sudo arping ${SUBNET1_IP} -c 3
    Log    ${ARP_TO_SUBNET}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${ARP_TO_SUBNET}
    Log    ${output}
    Should Contain    ${output}    Unicast
    Should Not Contain    ${output}    Received 0 reply
    Log    Generate ARP from target VM1 by arping to the subnet gateway IP. ( ping to subnet gw ip network )
    ${ARP_TO_SUBNET}=    Catenate    sudo arping ${SUBNET2_IP} -c 3
    Log    ${ARP_TO_SUBNET}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${ARP_TO_SUBNET}
    Log    ${output}
    Should Not Contain    ${output}    Received 0 reply
    Log    Validate Fib table
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    #    Should Contain    ${resp.content}    50.1.1.1
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    Should Contain    ${resp.content}    ${SUBNET2_IP}
    Wait Until Keyword Succeeds    5s    1s    Get MAC IP
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}

TC04 If anything other than subnet ip then no reply
    [Documentation]    If anything other than subnet ip then no reply
    Log    Validate 100% Loss
    ${PING_TO_Random}=    Catenate    ping ${OTHER_IP} -c 5
    Log    ${PING_TO_Random}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${PING_TO_Random}
    Log    ${output}
    Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output}    Get Fib Entries    session
    Should Not Contain    ${output}    ${OTHER_IP}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Not Contain    ${flow_output}    ${OTHER_IP}
    Sleep    10

TC05 Validate multiple mip migration
    [Documentation]    Validate multiple mip migration
    : FOR    ${i}    IN RANGE    1    4
    \    MIP Migration
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    ${output}=    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32".*"nextHopAddressList\\":\\["\\"${OS_COMPUTE_2_IP}\\"\\"]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    Bring down sub interface
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${UNCONFIG_EXTRA_ROUTE_IP1}

TC06 Same DPN MIP Migration
    [Documentation]    Same DPN MIP Migration
    Log    Bring up interface on VM1 in DPN1
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${rx_packet1_before}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0:1
    Log    ${rx_packet1_before}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    Should Contain    ${output}    broadcast
    ${output}    Get Fib Entries    session
     ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    Bring down interface on VM1 in DPN1
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    Sleep    5
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[1] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET2[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    5
    ${rx_packet2_before}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET2[0]}    ifconfig eth0:1
    Log    ${rx_packet2_before}
    Log    Generate ARP from VM2
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET2[0]}    ${RPING_MIP_IP_2}
    Should Contain    ${output}    Received 0 reply
    Log    Verify Ping
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET2[0]}    ping 60.1.1.110 -c 5
    Should Contain    ${output}    ${PING_REGEXP}
    Wait Until Keyword Succeeds    60s    5s    Get MAC IP
    ${output}    Get Fib Entries    session
     ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_4}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
     ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET2[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
     ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_4}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET2[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    ${resp}    RequestsLibrary.Get Request    session    /restconf/operational/odl-l3vpn:learnt-vpn-vip-to-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_4}
    Log    Bring down created sub-interface in VM2
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET2[0]}    ${UNCONFIG_EXTRA_ROUTE_IP1}

TC VPN TO VPN Migration
    [Documentation]    VPN A to VPN B
    Log    Bring up interface on VM1 in DPN1
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}     ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}     sudo ifconfig eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    Should Contain    ${output}    broadcast
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32".*"nextHopAddressList\\":\\["\\"${OS_COMPUTE_1_IP}\\"\\"]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    Dissocaiting network from L3VPN
    Dissociate L3VPN From Networks    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    Sleep    30
    ${output}    Get Fib Entries    session
    Log    ${output}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${net_id}
    Log    Creating new L3VPN
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[1]}    name=${VPN_NAME[1]}    rd=${CREATE_RD1}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[1]}
    Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${net_id}
    Sleep    45
    Log    Check FIB
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET2[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET2[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#   ${vm_instances} =    Create List    @{VM_IP_NET1}    @{VM_IP_NET2}     @{VM_IP_NET3}
#    Wait Until Keyword Succeeds    60s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD11}/    ${vm_instances}
    Log    Verify Ping between different networks
    Wait Until Keyword Succeeds    30s    10s    Verify Ping On Different ELAN
    [Teardown]    Run Keywords    Dissociate L3VPN From Networks    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[1]}
    ...    AND    Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}     AND     VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[1]}

TC07 Restart CSS
    [Documentation]    Restart CSS
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl show
    Log    ${output}
    ${CONFIG_EXTRA_ROUTE_IP} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP}
    Sleep    5
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    Should Contain    ${output}    eth0:1
    Log    CSS1 Restart
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Log    ${output}
    Sleep    5
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}
    Sleep    10
    #    :FOR    ${vmname}    IN    @{VM_INSTANCES_NET1}
    #    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    #    Log    ${output}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    Should Contain    ${output}    broadcast
    Wait Until Keyword Succeeds    60s    5s    Get MAC IP
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET2[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
     ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET2[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    Remove the sub-interface
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    #TC09 Restart Controller
    #    [Documentation]    Restart Controller
    #    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_1_IP}    ps -ef | grep karaf | grep -v grep
    #    Log    ${output}
    #    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_1_IP}    ps -ef | grep karaf | grep -v grep | awk '{print "sudo kill -9 " $2}' | sh
    #    Log    ${output}
    #    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_1_IP}    ps -ef | grep karaf
    #    Log    ${output}
    #    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_1_IP}    ${WORKSPACE}${/}${BUNDLEFOLDER}/bin/start
    #    Log    ${output}
    #    Sleep    5
    #    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_1_IP}    ps -ef | grep karaf
    #    Log    ${output}
    #    Log    Check interface on VM1
    #    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0
    #    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    #    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    #    Log    Bring up sub-interface on VM1
    #    ${CONFIG_EXTRA_ROUTE_IP} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    #    Log    ${CONFIG_EXTRA_ROUTE_IP}
    #    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP}
    #    Sleep    5
    #    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    #    Should Contain    ${output}    eth0:1
    #    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    #    Should Contain    ${output}    Received 0 reply
    #    Should Contain    ${output}    broadcast
    #    Sleep    5
    #    ${output}    Get Fib Entries    session
    #    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    #    Wait Until Keyword Succeeds    60s    5s    Get MAC IP
    #

TC08 Same ELAN
    [Documentation]    Same ELAN
    Log    Dissociate network from L3VPN
    Dissociate L3VPN From Networks    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${net_id}
    Log    Delete interfaces from router
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[0]}
    #    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    #    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[2]}
    ${vm_instances} =    Create List    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}    ${VM_IP_NET3[0]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRIES_URL}    ${vm_instances}
    Log    Bring inerface in VM2
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    5
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32".*"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    Wait Until Keyword Succeeds    60s    5s    Get MAC IP
    Wait Until Keyword Succeeds    30s    10s    Verify Ping On Same ELAN
    Wait Until Keyword Succeeds    60s    5s    Get MAC IP
    [Teardown]    Run Keywords    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[0]}
    ...    AND    Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}

TC09 Delete VM
    [Documentation]    Delete VM
    Log    Delete VM1
    Delete Vm Instance    ${VM_INSTANCES_NET1[0]}
    Delete Port    ${PORT_LIST[0]}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Not Contain    ${flow_output}    ${VM_IP_NET1[0]}
    ${output}    Get Fib Entries    session
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${FIB_ENTRY_1}

*** Keywords ***
Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}

Presuite Cleanup
    [Documentation]    Clean the already existing tunnels and tep interfaces
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_TRANSPORTZONE}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_INTERFACES}
    Log    ${resp.content}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Log    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Create Network    ${NETWORKS[2]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Should Contain    ${NET_LIST}    ${NETWORKS[2]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[2]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[4]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[5]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_NET3[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_NET3[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET1}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET3}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET1}    ${DHCP_IP1}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    Set Suite Variable    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET2}
    ${VM_IP_NET3}    ${DHCP_IP3}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET3}
    Log    ${VM_IP_NET3}
    Set Suite Variable    ${VM_IP_NET3}
    Log    Create Router
    Create Router    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    30s    10s    Verify Ping On Same ELAN
    Wait Until Keyword Succeeds    30s    10s    Verify Ping Fails On Different ELAN
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NEUTRON_ROUTERS_API}    ${router_list}
    Log    Add Interfaces to router
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[2]}
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}    ${VM_IP_NET3[0]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRIES_URL}    ${vm_instances}
    Log    Create a L3VPN and associate network1 and Router
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    Set Suite Variable    ${net_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    Set Suite Variable    ${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${net_id}
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Set Suite Variable    ${router_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}    ${VM_IP_NET3[0]}
    ...    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRIES_URL}    ${vm_instances}
    Log    VALIDATING MAC IP
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Log    Check Datapath Across DPNs
    Verify Ping On Same ELAN
    Verify Ping On Different ELAN
#    Create BGP Configuration    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
#    AddNeighbor To BGP Configuration       remoteas=${AS_ID}      neighborAddr=${DCGW_SYSTEM_IP}
#    AddVRF To BGP Configuration       rd="500:1"    impRT=${CREATE_IMPORT_RT[0]}     expRT=${CREATE_EXPORT_RT[0]}
#    ${output} =     Get BGP Configuration
#    Log     ${output}
#    Should Contain      ${output}     ${DCGW_SYSTEM_IP}
#    Add BGP Configuration On DCGW
#    ${output} =     Execute Command On DCGW     show running-config
#    Log    ${output}
#    ${output} =     Execute Command On DCGW     show bgp neighbors ${ODL_SYSTEM_IP}
#    Log    ${output}
#    Should Contain    ${output}    BGP state = Established

Verify Ping On Same ELAN
    [Documentation]    Verify Ping among VMs
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET1[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ping -c 3 ${VM_IP_NET3[1]}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Ping Fails On Different ELAN
    [Documentation]    Verify Ping among VMs
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET3[0]}
    Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET3[1]}
    Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${NO_PING_REGEXP}

Verify Ping On Different ELAN
    [Documentation]    Verify Ping among VMs
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET3[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET3[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Contain    ${flow_output}    table=21
    Log    ${resp}
    @{vm_ip}=    Create List
    Append To List    ${vm_ip}    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    : FOR    ${i}    IN    @{vm_ip}
    \    ${resp}=    Should Match regexp    ${flow_output}    table=21.*nw_dst=${i}

Get Fib Entries
    [Arguments]    ${session}
    [Documentation]    Get Fib table entries from ODL
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FIB_ENTRIES_URL}
    Log    ${resp.content}
    [Return]    ${resp.content}

Get MAC IP
    [Documentation]    Check for MAC
    ${resp}    RequestsLibrary.Get Request    session    /restconf/operational/odl-l3vpn:learnt-vpn-vip-to-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_2}

MIP Migration
    Log    Bring down sub-interface in dpn1 and create on dpn2
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    Should Not Contain    ${output}    eth0:1
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    Wait Until Keyword Succeeds    60s    5s    Get MAC IP
    Log    Bring down sub-interface in dpn2 and create on dpn1
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Not Contain    ${output}    eth0:1
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    Wait Until Keyword Succeeds    60s    5s    Get MAC IP

Add BGP Configuration On DCGW
    [Arguments]    ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    DCGW Suite Setup
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write      telnet localhost ${user}
    Log    ${output}
    ${output} =    Read Until    Password:
    Log    ${output}
    ${output} =    Write    ${password}
    Log    ${output}
    ${output} =    Read
    Log    ${output}
    ${output} =    Write    terminal length 512
    ${output} =    Write Commands Until Expected Prompt   configure terminal     ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   router bgp ${AS_ID}    ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   bgp router-id ${DCGW_SYSTEM_IP}     ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   redistribute static     ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   redistribute connected     ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   neighbor ${ODL_SYSTEM_IP} remote-as ${AS_ID}    ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   address-family vpnv4 unicast    ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   neighbor ${ODL_SYSTEM_IP} activate     ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   end     ${BGP_PROMPT}
    Log   ${output}
    ${output} =    Write Commands Until Expected Prompt   exit    ${BGP_PROMPT}
    Log   ${output}
    

Start Processes on ODL
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    ${dcgw_conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Set Suite Variable    ${dcgw_conn_id}
    Log    ${dcgw_conn_id}
    Utils.Flexible SSH Login     ${DEFAULT_USER}    ${EMPTY}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${output} =    Write Commands Until Expected Prompt      sudo /opt/quagga/etc/init.d/zrpcd start      ]>
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zrpcd     ]>
    ${output} =    Write Commands Until Expected Prompt     cd /opt/quagga/sbin/      ]>
    Log    ${output} 
    ${output} =    Write    sudo ./bgpd &
    ${output} =    Read Until     pid
    Log    ${output}
    ${output} =    Write    sudo ./zebra &
    ${output} =    Read Until     pid
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt      ps -ef | grep bgpd     ]>
    ${output} =    Write Commands Until Expected Prompt      ps -ef | grep zebra     ]>
    ${output} =    Write Commands Until Expected Prompt     cd /opt/quagga/etc/      ]>
    ${output} =    Write Commands Until Expected Prompt     ls -lrt      ]>
    Log    ${output}

Start Processes on DCGW 
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    DCGW Suite Setup
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start     ]>
    ${output} =    Read
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zrpcd     ]>
    ${output} =    Write Commands Until Expected Prompt     cd /opt/quagga/sbin/     ]>
    Log    ${output}
    ${output} =    Read
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ls -lrt     ]>
    ${output} =    Write     sudo ./bgpd &
    ${output} =    Read Until     pid
    Log    ${output}
    ${output} =    Write     sudo ./zebra &
    ${output} =    Read
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep bgpd     ]>
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zebra     ]>
    ${output} =    Write Commands Until Expected Prompt     cd /opt/quagga/etc/      ]>
    ${output} =    Write Commands Until Expected Prompt     ls -lrt      ]>
    ${output} =    Write Commands Until Expected Prompt     more zerba.conf      ]>
    Log    ${output}

Execute Command On DCGW
    [Arguments]    ${cmd}    ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write     telnet localhost ${user}
    Log    ${output}
    ${output} =    Read Until    Password:
    Log    ${output}
    ${output} =    Write    ${password}
    ${output} =    Read
    ${output} =    Write    terminal length 512
    ${output} =    Read
    ${output} =    Write Commands Until Expected Prompt    ${cmd}     ${BGP_PROMPT}
    Log    ${output}
    Write    exit
    [Return]    ${output}

Add Loopback Interface On DCGW
    [Arguments]    ${ip}    ${user}=zebra    ${password}=zebra
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write     telnet localhost ${user}
    Log    ${output}
    ${output} =    Read Until    Password:
    Log    ${output}
    ${output} =    Write    ${password}
    ${output} =    Read
    ${output} =    Write    terminal length 512
    ${output} =    Read
    ${output} =    Write    enable
    ${output} =    Read
    ${output} =    Write    ${password}
    ${output} =    Read
    Set Client Configuration    prompt=#
    ${output} =    Write    configure terminal
    ${output} =    Read
    ${output} =    Write    interface lo
    ${output} =    Read
    ${output} =    Write     ip address ${LOOPBACK_IP}
    ${output} =    Read
    ${output} =    Write     write terminal
    ${output} =    Read
    Log    ${output}
    Write    end
    Read
    Write     exit
    Read
    [Return]    ${output}

Create BGP Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/create_bgp    mapping=${Kwargs}    session=session

AddNeighbor To BGP Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/addNeighbor_bgp    mapping=${Kwargs}    session=session

AddVRF To BGP Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/addVRF_bgp    mapping=${Kwargs}    session=session

Get BGP Configuration
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    [Return]    ${resp.content}

Delete BGP Configuration
    [Documentation]    Delete BGP
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Create External Tunnel Endpoint Configuration
    [Arguments]    &{Kwargs}
    [Documentation]     Create Tunnel End point
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/create_etep    mapping=${Kwargs}    session=session

Delete External Tunnel Endpoint Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Delete Tunnel End point
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/delete_etep    mapping=${Kwargs}    session=session

Get External Tunnel Endpoint Configuration
    [Arguments]    ${ip}
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:dc-gateway-ip-list/dc-gateway-ip/${ip}/
    Log    ${resp.content}
    [Return]    ${resp.content}

DCGW Suite Setup
    [Documentation]    Login to the DCGW
    ${dcgw_conn_id}=    SSHLibrary.Open Connection    ${DCGW_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Set Suite Variable    ${dcgw_conn_id}
    Log    ${dcgw_conn_id}
    Utils.Flexible SSH Login    ${DEFAULT_USER}      ${EMPTY} 
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout} 

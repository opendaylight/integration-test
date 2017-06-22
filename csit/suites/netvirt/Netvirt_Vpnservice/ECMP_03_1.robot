*** Settings ***
Documentation     Test suite for ECMP - Verify traffic splitting on L3VPN within DC across VMs located on different CSSs
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/VpnOperations.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/DevstackUtils.robot
Resource          ${CURDIR}/../../../libraries/OpenStackOperations.robot
Resource          ${CURDIR}/../../../libraries/OVSDB.robot
Resource          ${CURDIR}/../../../libraries/L2GatewayOperations.robot
Library           OperatingSystem    #Resource    ${CURDIR}/../../../libraries/MultiPathKeywords.robot

*** Variables ***
@{Port_List}      Network1_Port1    Network1_Port2    Network1_Port3    Network1_Port4    Network1_Port5    Network1_Port6    Network1_Port7
...               Network1_Port8
@{VmList}         NOVA_VM11    NOVA_VM12    NOVA_VM13    NOVA_VM21    NOVA_VM22    NOVA_VM23    NOVA_VM31
...               NOVA_VM32
${SECURITY_GROUP}    custom-sg
${StaticIp}       100.100.100.100
${StaticIp2}      110.110.110.110
@{allowed_ip}     ${StaticIp}    ${StaticIp2}
${mask}           32
${mask_2}         24
${NoOfStaticIp}    1
${NoOfPingPackets}    15
${resp}           0
${PASS}           ${0}
${ExpectedPacketCount}    ${20}
${PING_REGEXP}    (\\d+)\\% packet loss

*** Testcases ***
TC01 Verify Distribution of traffic with weighted buckets-3 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify The CSC should support ECMP traffic splitting on L3VPN within DC across VMs located on different CSSs - Distribution of traffic with weighted buckets-3 VM on CSS1,2 VM on CSS2
    Log    Update the Router with ECMP Route
    @{VmIpList}    Create List    ${VmIpDict.${VmList[0]}}    ${VmIpDict.${VmList[1]}}    ${VmIpDict.${VmList[2]}}    ${VmIpDict.${VmList[3]}}    ${VmIpDict.${VmList[4]}}
#    ${VM_IPs}    ${DHCP_IP}    Collect VM IP Addresses    false    @{VmNameList}
    Configure Next Hop on Router    ${NoOfStaticIp}    ${VmIpList}    ${EMPTY}    ${mask}
    : FOR    ${VmIp}    IN    @{VmIpList}
    \    Configure Ip on Sub Interface    ${StaticIp}    ${VmIp}    ${mask_2}
    : FOR    ${VmIp}    IN    @{VmIpList}
    \    Verify Ip Configured on Sub Interface    ${StaticIp}    ${VmIp}
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/${mask}\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/${mask}\\s+${OS_COMPUTE_2_IP}
    Log    Verify the ECMP flow in all Compute Nodes
    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${3}    ${2}    ${StaticIp}
    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${2}    ${3}    ${StaticIp}
    ${Compute1PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
    ${Compute2PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
    Verify Ping to Sub Interface    ${StaticIp}    ${VmIpDict.${VmList[5]}}
    ${Compute1PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
    ${Compute2PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
    Log    Check via which Compute Packets are forwarded
    Run Keyword If    ${Compute1PacketCountAfterPing}==${Compute1PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute 1
    ...    AND    Verify Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
    ...    ELSE IF    ${Compute2PacketCountAfterPing}==${Compute2PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute 2
    ...    AND    Verify Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
    ...    ELSE    Log    Packets are not forwarded by any of the Compute Nodes

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    DevstackUtils.Devstack Suite Setup
    #SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Create Setup

End Suite
    [Documentation]    Run at end of the suite
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create networks,subnets,ports and VMs,tep ports
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet_1}=    Set Variable    ${first_two_octets}.0.0/16
    Set Global Variable    ${subnet_1}
    Comment    "Configure ITM tunnel between DPNs"
    ${Dpn1Id}    Get DPID    ${OS_COMPUTE_1_IP}
    ${Dpn2Id}    Get DPID    ${OS_COMPUTE_2_IP}
    ${Dpn3Id}    Get DPID    ${OS_COMPUTE_3_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
    Issue Command On Karaf Console    tep:add ${Dpn1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:add ${Dpn2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:add ${Dpn3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:commit
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Comment    "Creating customised security Group and Rules"
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Comment    "Create Neutron Network , Subnet and Ports"
    Create Network    Network1
    Create SubNet    Network1    Subnet1    10.10.1.0/24
    ${ADD_ARG}    Catenate    --security-group    ${SECURITY_GROUP}
    : FOR    ${portname}    IN    @{Port_List}
    \    Create Port    Network1    ${portname}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    Log To Console    "Creating VM on Compute 1"
    Create Vm Instance With Port On Compute Node    ${Port_List[0]}    ${VmList[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[1]}    ${VmList[1]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[2]}    ${VmList[2]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Log To Console    "Creating VM on Compute 2"
    Create Vm Instance With Port On Compute Node    ${Port_List[3]}    ${VmList[3]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[4]}    ${VmList[4]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[5]}    ${VmList[5]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Log to Console    "Creating VM on Compute 3"
    Create Vm Instance With Port On Compute Node    ${Port_List[6]}    ${VmList[6]}    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[7]}    ${VmList[7]}    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Create Router    Router1
    Add Router Interface    Router1    Subnet1
    
    #@{PingVmList}    Create List    NOVA_VM23    NOVA_VM31    NOVA_VM13
    &{VmIpDict}    Create Dictionary
    #${VM_IPs}    ${DHCP_IP}    Collect VM IP Addresses    false    @{VmList}
    #Log    ${VM_IPs}
    :For    ${VmName}    IN    @{VmList}
    \    ${VmIp}    Wait Until Keyword Succeeds    30s    2s    Verify Nova VM IP    ${VmName}
    \    Set To Dictionary    ${VmIpDict}    ${VmName}=${VmIp[0]}
    Log    ${VmIpDict}
    Set Global Variable    ${VmIpDict}

Delete Setup
    [Documentation]    Clean the config created for ECMP TCs
    Append To List    ${VmList}    NOVA_VM24    NOVA_VM25
    : FOR    ${VmName}    IN    @{VmList}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VmName}
    : FOR    ${portname}    IN    @{Port_List}
    \    Run Keyword And Ignore Error    Delete Port    ${portname}
    Run Keyword And Ignore Error    Update Router    Router1    --no-routes
    Run Keyword And Ignore Error    Remove Interface    Router1    Subnet1
    Run Keyword And Ignore Error    Delete Router    Router1
    Run Keyword And Ignore Error    Delete SubNet    Subnet1
    Run Keyword And Ignore Error    Delete Network    Network1
    ${Dpn1Id}    Get DPID    ${OS_COMPUTE_1_IP}
    ${Dpn2Id}    Get DPID    ${OS_COMPUTE_2_IP}
    ${Dpn3Id}    Get DPID    ${OS_COMPUTE_3_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
    Issue Command On Karaf Console    tep:delete ${Dpn1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:delete ${Dpn2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_2} null TZA
    Issue Command On Karaf Console    tep:delete ${Dpn3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_2} null TZA
    Issue Command On Karaf Console    tep:commit

Verify flows in Compute Node
    [Arguments]    ${ip}    ${ExpectedLocalBucketEntry}    ${ExpectedRemoteBucketEntry}    ${StaticIp}
    [Documentation]    Verify flows w.r.t a particular ip and the corresponding bucket entry
    ${OvsFlow}    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${OvsGroup}    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${match}    ${ECMPgrp}    Should Match Regexp    ${OvsFlow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${OvsGroup}    group_id=${ECMPgrp},type=select.*
    ${ActualLocalBucketEntry}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${ActualLocalBucketEntry}    ${ExpectedLocalBucketEntry}
    ${ActualRemoteBucketEntry}    Get Regexp Matches    ${EcmpGroup}    resubmit
    Length Should Be    ${ActualRemoteBucketEntry}    ${ExpectedRemoteBucketEntry}

Verify Packet Count
    [Arguments]    ${ComputeIp}    ${StaticIp}
    [Documentation]    Verify flows w.r.t a particular ip and packet count after ping
    Comment    Verify the flow and packet count
    ${OvsFlow}    Run Command On Remote System    ${ComputeIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${OvsGroupStat}    Run Command On Remote System    ${ComputeIp}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${match}    ${TotalPacketCount}    ${ECMPgrp}    Should Match Regexp    ${OvsFlow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroupStat}    Should Match Regexp    ${OvsGroupStat}    group_id=${ECMPgrp}.*
    ${BucketPacketCount}    Get Regexp Matches    ${EcmpGroupStat}    :packet_count=(..)    1
    ${TotalPacketCount}    ConvertToInteger    ${TotalPacketCount}
    ${TotalOfBucketPacketCount}    Set Variable    ${0}
    : FOR    ${count}    IN    @{BucketPacketCount}
    \    ${TotalOfBucketPacketCount}    Evaluate    ${TotalOfBucketPacketCount}+int(${count})
    Log    ${TotalOfBucketPacketCount}
    Should Be Equal    ${TotalPacketCount}    ${TotalOfBucketPacketCount}

Get table21 Packet Count
    [Arguments]    ${ComputeIp}    ${StaticIp}
    [Documentation]    Get the packet count from table 21 for the specified Ip
    ${OvsFlow}    Run Command On Remote System    ${ComputeIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${match}    ${PacketCount}    Should Match Regexp    ${OvsFlow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*
    Log    ${PacketCount}
    [Return]    ${PacketCount}

Generate Next Hop
    [Arguments]    ${ip}    ${mask}    @{VmIpList}
    [Documentation]    Key word for generating next hop entries
    #    Log    Collect VM Ip's
    #    ${VM_IPs}    ${DHCP_IP}    Collect VM IP Addresses    false    @{VmNameList}
    #    Log    ${VM_IPs}
    #    :For    ${VmName}    ${VmIp}    IN ZIP    ${VmNameList}    ${VM_IPs}
    #    Set To Dictionary    ${VmIpDict}    ${VmName}=${VmIp}
    #    Log    ${VmIpDict}
    @{NextHopList}    Create List
    : FOR    ${VmIp}    IN    @{VmIpList}
    \    #    ${VmIp}    Get VM IP    ${VmName}
    \    Append To List    ${NextHopList}    --route destination=${ip}/${mask},gateway=${VmIp}
    [Return]    @{NextHopList}

Configure Next Hop on Router
    [Arguments]    ${val}    ${VmList1}    ${VmList2}    ${mask}
    [Documentation]    Key word for updating Next Hop Routes
    @{NextHopList_1}    Generate Next Hop    ${staticip}    ${mask}    @{VmList1}
    @{NextHopList_2}    Run Keyword if    ${val}==${2}    Generate Next Hop    ${staticip2}    ${mask}    @{VmList2}

    ${routes1}    catenate    @{NextHopList_1}
    ${routes2}    catenate    @{NextHopList_2}
    ${finalroute}    Set Variable If    ${val}==${2}    ${routes1} ${routes2}    ${routes1}
    Log    ${finalroute}
    Log    Updating the router with next hops
    Update Router    Router1    ${finalroute}
    Log    Display the router configurations
    Show Router    Router1    -D

Configure Ip on Sub Interface
    [Arguments]    ${ip}    ${VmIp}    ${mask}
    [Documentation]    Key word for configuring Ip on sub interface
    Wait Until keyword succeeds    100s    20s    Run Keyword    Execute Command on VM Instance    Network1    ${VmIp}
    ...    sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 up
    #    Wait Until keyword succeeds    100s    20s    Run Keyword    Execute command on server    sudo ifconfig eth0:0 ${ip}/${mask} up
    ...    # ${VmName}

Verify Ip Configured on Sub Interface
    [Arguments]    ${Ip}    ${VmIp}
    [Documentation]    Key word for verifying Ip configured on sub interface
    ${resp}    Execute Command on VM Instance    Network1    ${VmIp}    sudo ifconfig eth0:0
    #Execute Command on server    sudo ifconfig eth0:0    ${VmName}
    Should Contain    ${resp}    ${Ip}

Verify Ping to Sub Interface
    [Arguments]    ${Ip}    ${VmName}
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${PingVM_IPs[0]}    ping ${StaticIp} -c 15
    ${match}    ${PacketCount}    Should Match Regexp    ${pingresp}    ${PING_REGEXP}
    #(\\d+)\\% packet loss
    ${resp}    Run Keyword If    ${PacketCount}<=${20}    Evaluate    ${resp}+0
    ...    ELSE    Evaluate    ${resp}+1
    Should Be Equal    ${resp}    ${PASS}

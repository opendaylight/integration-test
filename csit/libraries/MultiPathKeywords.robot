*** Settings ***
Documentation     Multi path library.
Library           SSHLibrary
Resource          Utils.robot
Resource          OVSDB.robot
Resource          OpenStackOperations.robot

*** Variables ***
${resp}    0
${PING_PASS}    ${0}
${ExpectedPacketCount}    20
${PING_REGEXP}    (\\d+)\\% packet loss
${NoOfPingPackets}    15
${DumpFlows}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
${DumpGroups}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
${DumpGroupStats}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int

*** Keywords ***
Verify flows in Compute Node
    [Arguments]    ${ip}    ${ExpectedLocalBucketEntry}    ${ExpectedRemoteBucketEntry}    ${StaticIp}
    [Documentation]    Verify flows w.r.t a particular ip and the corresponding bucket entry
    ${OvsFlow}    Run Command On Remote System    ${ip}    ${DumpFlows}
    ${OvsGroup}    Run Command On Remote System    ${ip}    ${DumpGroups}
    ${match}    ${ECMPgrp}    Should Match Regexp    ${OvsFlow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${OvsGroup}    group_id=${ECMPgrp},type=select.*
    ${ActualLocalBucketEntry}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${ActualLocalBucketEntry}    ${ExpectedLocalBucketEntry}
    ${ActualRemoteBucketEntry}    Get Regexp Matches    ${EcmpGroup}    resubmit
    Length Should Be    ${ActualRemoteBucketEntry}    ${ExpectedRemoteBucketEntry}

Verify Packet Count
    [Arguments]    ${ComputeIp}    ${StaticIp}
    [Documentation]    Verify flows w.r.t a particular ip and packet count after ping

    ${OvsFlow}    Run Command On Remote System    ${ComputeIp}    ${DumpFlows}
    ${OvsGroupStat}    Run Command On Remote System    ${ComputeIp}    ${DumpGroupStats}
    ${match}    ${TotalPacketCount}    ${ECMPgrp}    Should Match Regexp    ${OvsFlow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroupStat}    ${EcmpGroupPacketCount}    Should Match Regexp    ${OvsGroupStat}    group_id=${ECMPgrp}.*,packet_count=(\\d+).*
    ${BucketPacketCount}    Get Regexp Matches    ${EcmpGroupStat}    :packet_count=(..)    1
    ${TotalPacketCount}    ConvertToInteger    ${EcmpGroupPacketCount}
    ${TotalOfBucketPacketCount}    Set Variable    ${0}
    : FOR    ${count}    IN    @{BucketPacketCount}
    \    ${TotalOfBucketPacketCount}    Evaluate    ${TotalOfBucketPacketCount}+int(${count})
    Log    ${TotalOfBucketPacketCount}
    Should Be Equal    ${TotalPacketCount}    ${TotalOfBucketPacketCount}

Get table21 Packet Count
    [Arguments]    ${ComputeIp}    ${StaticIp}
    [Documentation]    Get the packet count from table 21 for the specified Ip
    ${OvsFlow}    Run Command On Remote System    ${ComputeIp}    ${DumpFlows}
    ${match}    ${PacketCount}    Should Match Regexp    ${OvsFlow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*
    Log    ${PacketCount}
    [Return]    ${PacketCount}

Generate Next Hop
    [Arguments]    ${ip}    ${mask}    @{VmIpList}
    [Documentation]    Key word for generating next hop entries
    @{NextHopList}    Create List
    : FOR    ${VmIp}    IN    @{VmIpList}
    \    Append To List    ${NextHopList}    --route destination=${ip}/${mask},gateway=${VmIp}
    [Return]    @{NextHopList}

Configure Next Hop on Router
    [Arguments]    ${Router_Name}    ${val}    ${VmList1}    ${VmList2}={EMPTY}    ${mask}
    [Documentation]    Key word for updating Next Hop Routes
    @{NextHopList_1}    Generate Next Hop    ${staticip}    ${mask}    @{VmList1}
    @{NextHopList_2}    Run Keyword if    ${val}==${2}    Generate Next Hop    ${staticip2}    ${mask}    @{VmList2}
    ${routes1}    catenate    @{NextHopList_1}
    ${routes2}    catenate    @{NextHopList_2}
    ${finalroute}    Set Variable If    ${val}==${2}    ${routes1} ${routes2}    ${routes1}
    Log    ${finalroute}
    Log    Updating the router with next hops
    Update Router    ${Router_Name}    ${finalroute}
    Log    Display the router configurations
    Show Router    ${Router_Name}    -D

Configure Ip on Sub Interface
    [Arguments]    ${Network_Name}    ${ip}    ${VmIp}    ${mask}
    [Documentation]    Key word for configuring Ip on sub interface
    Wait Until keyword succeeds    100s    20s    Run Keyword    Execute Command on VM Instance    ${Network_Name}    ${VmIp}
    ...    sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 up

Verify Ip Configured on Sub Interface
    [Arguments]    ${Network_Name}    ${Ip}    ${VmIp}
    [Documentation]    Key word for verifying Ip configured on sub interface
    ${resp}    Execute Command on VM Instance    ${Network_Name}    ${VmIp}    sudo ifconfig eth0:0
    Should Contain    ${resp}    ${Ip}

Verify Ping to Sub Interface
    [Arguments]    ${Network_Name}    ${Ip}    ${VmIp}
    [Documentation]    Keyword to ping sub interface
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    ${Network_Name}    ${VmIp}    ping ${StaticIp} -c ${NoOfPingPackets}
    ${match}    ${PacketCount}    Should Match Regexp    ${pingresp}    ${PING_REGEXP}
    ${resp}    Run Keyword If    ${PacketCount}<=${20}    Evaluate    ${resp}+0
    ...    ELSE    Evaluate    ${resp}+1
    Should Be Equal    ${resp}    ${PING_PASS}

Tep Port Operations
    [Arguments]    ${Operation}
    [Documentation]    Keyword to add/delete tep port
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet_1}=    Set Variable    ${first_two_octets}.0.0/16
    ${ComputeNode1Id}    Get DPID    ${OS_COMPUTE_1_IP}
    ${ComputeNode2Id}    Get DPID    ${OS_COMPUTE_2_IP}
    ${ComputeNode3Id}    Get DPID    ${OS_COMPUTE_3_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
    Issue Command On Karaf Console    tep:${Operation} ${ComputeNode1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:${Operation} ${ComputeNode2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:${Operation} ${ComputeNode3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:commit

Verify Ping and Packet Count
    [Arguments]    ${Network_Name}    ${Ip}    ${VmName}
    [Documentation]    Keyword to Verify Ping and Packet count

    ${Compute1PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${Ip}
    ${Compute2PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${Ip}
    ${Compute3PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_3_IP}    ${Ip}
    Verify Ping to Sub Interface    ${Network_Name}    ${Ip}    ${VmName}
    ${Compute1PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${Ip}
    ${Compute2PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${Ip}
    ${Compute3PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_3_IP}    ${Ip}

    Log    Check via which Compute Node Packets are forwarded

    Run Keyword If    ${Compute1PacketCountAfterPing}==${Compute1PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute Node 1    AND    Verify Packet Count    ${OS_COMPUTE_1_IP}    ${Ip}
    ...    ELSE IF    ${Compute2PacketCountAfterPing}==${Compute2PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute Node 2    AND    Verify Packet Count    ${OS_COMPUTE_2_IP}    ${Ip}
    ...    ELSE IF    ${Compute3PacketCountAfterPing}==${Compute3PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute Node 3    AND    Verify Packet Count    ${OS_COMPUTE_3_IP}    ${Ip}
    ...    ELSE    Log    Packets are not forwarded by any of the Compute Nodes

Verify VM MAC in groups
    [Arguments]    ${ComputeIp}    ${StaticIp}    ${LocalVmPortList}    ${RemoteVmPortList}
    [Documentation]    Keyword to verify vm mac in respective compute node groups

    ${LocalVmMacList}    Get Ports MacAddr    ${LocalVmPortList}
    ${RemoteVmMacList}    Get Ports MacAddr    ${RemoteVmPortList}
    Log    ${LocalVmMacList}
    Log    ${RemoteVmMacList}

    ${OvsFlow}    Run Command On Remote System    ${ComputeIp}    ${DumpFlows}
    ${match}    ${grp1}    Should Match Regexp    ${OvsFlow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${OvsGroup}    Run Command On Remote System    ${ComputeIp}    ${DumpGroups}
    ${EcmpGroup}    Should Match Regexp    ${OvsGroup}    group_id=${grp1}.*
    :FOR    ${VmMac}    IN    @{RemoteVmMacList}
    \    Should Contain    ${EcmpGroup}    ${VmMac}

    ${LocalGroups}    Get Regexp Matches    ${EcmpGroup}    :15(\\d+)
    :FOR    ${VmMac}    ${GroupId}    In Zip    ${LocalVmMacList}    ${LocalGroups}
    \    ${val_1}    ${GroupNum}    Split String    ${GroupId}    :
    \    ${match}    Should Match Regexp    ${OvsGroup}    group_id=${GroupNum}.*bucket=actions.*
    \    Run Keyword and Ignore Error    Should Contain    ${match}    ${VmMac}


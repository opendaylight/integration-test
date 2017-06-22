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
    @{VmNameList}    Create List    NOVA_VM11    NOVA_VM12    NOVA_VM13    NOVA_VM21    NOVA_VM22
    ${VM_IPs}    ${DHCP_IP}    Collect VM IP Addresses    false    @{VmNameList}
    Configure Next Hop on Router    ${NoOfStaticIp}    ${VM_IPs}    ${EMPTY}    ${mask}
    : FOR    ${VmIp}    IN    @{VM_IPs}
    \    Configure Ip on Sub Interface    ${StaticIp}    ${VmIp}    ${mask_2}
    : FOR    ${VmIp}    IN    @{VM_IPs}
    \    Verify Ip Configured on Sub Interface    ${StaticIp}    ${VmIp}
    #    Log    Update the Router with ECMP Route
    #    ${RouterUpdateCmd}    Set Variable    --route destination=${StaticIp}/32,gateway=${VM_IPs[0]} --route destination=${StaticIp}/32,gateway=${VM_IPs[1]} --route destination=${StaticIp}/32,gateway=${VM_IPs[2]} --route destination=${StaticIp}/32,gateway=${VM_IPs[3]} --route destination=${StaticIp}/32,gateway=${VM_IPs[4]}
    #    Update Router    Router1    ${RouterUpdateCmd}
    #    Show Router    Router1    -D
    #    Comment    Configure StaticIp on VMs
    #    Wait Until Keyword Succeeds    100s    20s    Run Keywords    Execute Command on VM Instance    Network1
    ...    # ${VM_IPs[0]}
    #    ...    sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 up
    #    ...
    ...    # AND    Execute Command on VM Instance    Network1    ${VM_IPs[1]}    sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 up
    #    ...
    ...    # AND    Execute Command on VM Instance    Network1    ${VM_IPs[2]}    sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 up
    #    ...
    ...    # AND    Execute Command on VM Instance    Network1    ${VM_IPs[3]}    sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 up
    #    ...
    ...    # AND    Execute Command on VM Instance    Network1    ${VM_IPs[4]}    sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 up
    #    Comment    Verify Static IP got configured on VMs
    #    Verify Static Ip Configured In VM    ${VM_IPs[0]}    Network1    ${StaticIp}
    #    Verify Static Ip Configured In VM    ${VM_IPs[1]}    Network1    ${StaticIp}
    #    Verify Static Ip Configured In VM    ${VM_IPs[2]}    Network1    ${StaticIp}
    #    Verify Static Ip Configured In VM    ${VM_IPs[3]}    Network1    ${StaticIp}
    #    Verify Static Ip Configured In VM    ${VM_IPs[4]}    Network1    ${StaticIp}
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    Log    Verify the ECMP flow in all Compute Nodes
    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${3}    ${2}    ${StaticIp}
    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${2}    ${3}    ${StaticIp}
    ${Compute1PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
    ${Compute2PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
    Verify Ping to Sub Interface    ${StaticIp}    ${PingVM_IPs[0]}
    ${Compute1PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
    ${Compute2PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
    Log    Check via which Compute Packets are forwarded
    Run Keyword If    ${Compute1PacketCountAfterPing}==${Compute1PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute 1
    ...    AND    Verify Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
    ...    ELSE IF    ${Compute2PacketCountAfterPing}==${Compute2PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute 2
    ...    AND    Verify Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
    ...    ELSE    Log    Packets are not forwarded by any of the Compute Nodes
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    Log    ${Ovs1Flow}
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    Log    ${Ovs2Flow}
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    Log    ${Ovs1Group}
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    Log    ${Ovs2Group}
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    ${Ovs1GroupStat}
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    ${Ovs2GroupStat}
    #    Log    Verify the flow for Co-located ECMP route
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    ##    Length Should Be    ${bucketCount}    ${3}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    ##    Length Should Be    ${RemoteVmBucket}    ${2}
    ##    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ##    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ##    Log    ${EcmpGroup}
    ##    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    ##    Log    ${bucketCount}
    ##    Length Should Be    ${bucketCount}    ${2}
    ##    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    ##    Log    ${RemoteVmBucket}
    ##    Length Should Be    ${RemoteVmBucket}    ${3}
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Comment    Verify the ECMP flow in switch
    #    Verify Packet Count after Ping    ${OS_COMPUTE_1_IP}    ${StaticIp}
    #    Verify Packet Count after Ping    ${OS_COMPUTE_2_IP}    ${StaticIp}
    #    Log    Verify ECMP flow
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    Log    ${Ovs1Flow}
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    Log    ${Ovs2Flow}
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    Log    ${Ovs1Group}
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    Log    ${Ovs2Group}
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    ${Ovs1GroupStat}
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    ${Ovs2GroupStat}
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroupStat}    bucket(\\d+):packet_count=(\\d+)
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroupStat}    bucket(\\d+):packet_count=(\\d+)
    Should Be Equal    ${fail_resp}    ${0}
    #TC02 Verify The ECMP flow should be added into all CSSs that have the footprint of the L3VPN and hosting Nexthop VM
    #    [Documentation]    Verify The ECMP flow should be added into all CSSs that have the footprint of the L3VPN and hosting Nexthop VM
    #    Log    Verify the ECMP flow in switch3
    #    ${Ovs3Flow}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs3Group}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${match}    Should Not Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}
    #    Create Vm Instance With Port On Compute Node    Network1_Port7    NOVA_VM31    ${OS_COMPUTE_3_IP}
    #    @{Vm31List}    Create List    NOVA_VM31
    #    ${VM31_IP}    ${DHCP_IP}    Collect VM IP Addresses    false    @{Vm31List}
    #    Append To List    ${VM_IPs}    ${VM31_IP[0]}
    #    Log    Verify the Routes in controller
    #    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    #    Log    ${CtrlFib}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    #    Should Match Regexp    ${CtrlFib}    ${VM31_IP[0]}\/32\\s+${OS_COMPUTE_3_IP}
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs3Flow}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs3Group}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs3GroupStat}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    Verify the flow for Co-located ECMP route
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${3}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${2}
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${2}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${3}
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs3Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${0}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${5}
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM31_IP[0]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Log    Delete VM (NOVA_VM31) from DPN3
    #    Delete Vm Instance    NOVA_VM31
    #    Sleep    ${10}
    #    Log    Verify the Routes in controller
    #    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    #    Log    ${CtrlFib}
    #    Should Not Match Regexp    ${CtrlFib}    ${VM31_IP[0]}\/32\\s+${OS_COMPUTE_3_IP}
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs3Flow}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs3Group}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs3GroupStat}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Comment    Verify flow got removed from DPN3
    #    ${match}    ${ECMPgrp}    Should Not Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Should Be Equal    ${fail_resp}    ${0}
    #    #${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    #${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    #${Ovs3GroupStat}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    #Should Be Equal    ${fail_resp}    ${0}
    #
    #TC03 Verify Distribution of traffic with weighted buckets - 2 VM on CSS1 , 2 VM on CSS2
    #    [Documentation]    Verify Distribution of traffic with weighted buckets - 2 VM on CSS1 , 2 VM on CSS2
    #    Log    Update the Router with ECMP Route
    #    ${RouterUpdateCmd}    Set Variable    --route destination=${StaticIp}/32,gateway=${VM_IPs[0]} --route destination=${StaticIp}/32,gateway=${VM_IPs[1]} --route destination=${StaticIp}/32,gateway=${VM_IPs[3]} --route destination=${StaticIp}/32,gateway=${VM_IPs[4]}
    #    Update Router    Router1    ${RouterUpdateCmd}
    #    Wait Until Keyword Succeeds    100s    20s    Run Keywords    Execute Command on VM Instance    Network1
    ...    # ${VM_IPs[0]}
    #    ...    sudo ifconfig eth0:0 ${StaticIp}/24 up
    #    ...
    ...    # AND    Execute Command on VM Instance    Network1    ${VM_IPs[1]}    sudo ifconfig eth0:0 ${StaticIp}/24 up
    #    ...
    ...    # AND    Execute Command on VM Instance    Network1    ${VM_IPs[3]}    sudo ifconfig eth0:0 ${StaticIp}/24 up
    #    ...
    ...    # AND    Execute Command on VM Instance    Network1    ${VM_IPs[4]}    sudo ifconfig eth0:0 ${StaticIp}/24 up
    #    Comment    Verify Static IP got configured on VMs
    #    Verify Static Ip Configured In VM    ${VM_IPs[0]}    Network1    ${StaticIp}
    #    Verify Static Ip Configured In VM    ${VM_IPs[1]}    Network1    ${StaticIp}
    #    Verify Static Ip Configured In VM    ${VM_IPs[3]}    Network1    ${StaticIp}
    #    Verify Static Ip Configured In VM    ${VM_IPs[4]}    Network1    ${StaticIp}
    #    Log    Verify the Routes in controller
    #    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    #    Log    ${CtrlFib}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    Verify the flow for Co-located ECMP route
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${2}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${1}
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${1}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${2}
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroup}    ${PacketCount}
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroup}    ${PacketCount}
    #    Log    Delete a VM (NOVA_VM12) from DPN1
    #    Delete Vm Instance    NOVA_VM12
    #    Sleep    10
    #    Log    Verify the Routes in controller
    #    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    #    Log    ${CtrlFib}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    #    Should Not Match Regexp    ${CtrlFib}    ${VM_IPs[1]}\/32\\s+${OS_COMPUTE_1_IP}
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    Verify the flow for Co-located ECMP route
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${1}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${1}
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${1}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${1}
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${match}    ${PacketCount}    ${ECMP1grp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMP1grp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroupStat}    ${PacketCount}
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroupStat}    ${PacketCount}
    #    Log    Delete another VM (NOVA_VM11) from DPN1
    #    Delete Vm Instance    NOVA_VM11
    #    Sleep    10
    #    Log    Verify the Routes in controller
    #    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    #    Log    ${CtrlFib}
    #    Should Not Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    #    Should Not Match Regexp    ${CtrlFib}    ${VM_IPs[0]}\/32\\s+${OS_COMPUTE_1_IP}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    Verify the flow for Co-located ECMP route
    #    ${match}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*resubmit\\(,220
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMP1grp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${0}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${1}
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    Length Should Be    ${bucketCount}    ${1}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    Length Should Be    ${RemoteVmBucket}    ${0}
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroupStat}    ${bucketCount}
    #    Should Be Equal    ${fail_resp}    ${0}
    #
    #TC04 Verify Distribution of traffic with weighted buckets - Add VM on CSS1
    #    [Documentation]    263.3.2 Verify Distribution of traffic with weighted buckets - Add VM on CSS1
    #    Log    Create the VMs on DPN1 configured as next-hop
    #    Create Vm Instance With Port On Compute Node    Network1_Port1    NOVA_VM11    ${OS_COMPUTE_1_IP}
    #    Wait Until Keyword Succeeds    100s    20s    Run Keyword    Execute Command on VM Instance    Network1
    ...    # ${VM_IPs[0]}
    #    ...    sudo ifconfig eth0:0 ${StaticIp}/24 up
    #    Comment    Verify Static IP got configured on VMs
    #    Verify Static Ip Configured In VM    ${VM_IPs[0]}    Network1    ${StaticIp}
    #    Log    Verify the Routes in controller
    #    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    #    Log    ${CtrlFib}
    #    #Should Not Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    #    Should Match Regexp    ${CtrlFib}    ${VM_IPs[0]}\/32\\s+${OS_COMPUTE_1_IP}
    #    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    Verify the flow for Co-located ECMP route
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    #Length Should Be    ${bucketCount}    ${1}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    #Length Should Be    ${RemoteVmBucket}    ${1}
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    #Length Should Be    ${bucketCount}    ${1}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    #Length Should Be    ${RemoteVmBucket}    ${1}
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroupStat}    ${PacketCount}
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroupStat}    ${PacketCount}
    #    Comment    Create a VM on Switch1
    #    Create Vm Instance With Port On Compute Node    Network1_Port2    NOVA_VM12    ${OS_COMPUTE_1_IP}
    #    Wait Until Keyword Succeeds    100s    20s    Run Keyword    Execute Command on VM Instance    Network1
    ...    # ${VM_IPs[1]}
    #    ...    sudo ifconfig eth0:0 ${StaticIp}/24 up
    #    Log    Verify the Routes in controller
    #    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    #    Log    ${CtrlFib}
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    Log    Verify the flow for Co-located ECMP route
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    #Length Should Be    ${bucketCount}    ${2}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    #Length Should Be    ${RemoteVmBucket}    ${1}
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Log    ${EcmpGroup}    ${bucketCount}
    #    #Length Should Be    ${bucketCount}    ${1}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Log    ${RemoteVmBucket}
    #    #Length Should Be    ${RemoteVmBucket}    ${2}
    #    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    #    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    #    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    #    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    #    ...
    ...    # ELSE    Evaluate    ${fail_resp}+1
    #    Log    Verify the ECMP flow in switch
    #    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroupStat}    ${PacketCount}
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${EcmpGroupStat}    ${PacketCount}
    #    Should Be Equal    ${fail_resp}    ${0}

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
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_2_IP}    .    2
    ${subnet_2}=    Set Variable    ${first_two_octets}.0.0/16
    Comment    "Configure ITM tunnel between DPNs"
    ${Dpn1Id}    Get DPID    ${OS_COMPUTE_1_IP}
    ${Dpn2Id}    Get DPID    ${OS_COMPUTE_2_IP}
    ${Dpn3Id}    Get DPID    ${OS_COMPUTE_3_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
    Issue Command On Karaf Console    tep:add ${Dpn1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:add ${Dpn2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_2} null TZA
    Issue Command On Karaf Console    tep:add ${Dpn3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_2} null TZA
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
    #    Create Port    Network1    Network1_Port1    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    #    Create Port    Network1    Network1_Port2    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    #    Create Port    Network1    Network1_Port3    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    #    Create Port    Network1    Network1_Port4    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    #    Create Port    Network1    Network1_Port5    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    #    Create Port    Network1    Network1_Port6    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    #    Create Port    Network1    Network1_Port7    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    Log To Console    "Creating VM on switch 1"
    Create Vm Instance With Port On Compute Node    Network1_Port1    NOVA_VM11    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    Network1_Port2    NOVA_VM12    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    Network1_Port3    NOVA_VM13    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Log To Console    "Creating VM on switch 2"
    Create Vm Instance With Port On Compute Node    Network1_Port4    NOVA_VM21    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    Network1_Port5    NOVA_VM22    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    Network1_Port6    NOVA_VM23    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Log to Console    "Creating VM on switch 3"
    Create Vm Instance With Port On Compute Node    Network1_Port7    NOVA_VM31    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    Network1_Port8    NOVA_VM32    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Comment    Create Router
    Create Router    Router1
    #Comment    Create BgpVpn
    #${Additional_Args}    Set Variable    -- --route-distinguishers list=true 100:10 100:11 100:12 100:13 100:14 --route-targets 100:1
    #${vpnid}    Create Bgpvpn    Vpn1    ${Additional_Args}
    #Comment    Add Networks to Neutron Router and Associate To L3vpn
    #Comment    "Associate Subnet1 to Router1"
    Add Router Interface    Router1    Subnet1
    #Log    "Associate Router1 to VPN1"
    #Bgpvpn Router Associate    Router1    Vpn1
    @{PingVmList}    Create List    NOVA_VM23    NOVA_VM31    NOVA_VM13
    #    ...    NOVA_VM23
    #    Set Global Variable    ${VmList}
    #    &{VmIpDict}    Create Dictionary
    ${PingVM_IPs}    ${DHCP_IP}    Collect VM IP Addresses    false    @{PingVmList}
    Set Global Variable    ${PingVM_IPs}
    #    Log    ${VM_IPs}
    #    :For    ${VmName}    ${VmIp}    IN ZIP    ${VmList}    ${VM_IPs}
    #    Set To Dictionary    ${VmIpDict}    ${VmName}=${VmIp}
    #    Log    ${VmIpDict}
    #    Set Global Variable    ${VmIpDict}
    #Log    Verify the ping
    #Ping Vm From DHCP Namespace    Network1    ${VM_IPs[0]}
    #${pingresp}    Wait Until Keyword Succeeds    120s    10s    Execute Command on VM Instance    Network1    ${VM_IPs[0]}
    #...    ping -c 15 ${VM_IPs[3]}
    #Log    ${pingresp}

Delete Setup
    [Documentation]    Clean the config created for ECMP TCs
    Append To List    ${VmList}    NOVA_VM24    NOVA_VM25
    Log    Deleting all VMs
    : FOR    ${VmName}    IN    @{VmList}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VmName}
    Log    Deleting all Ports
    : FOR    ${portname}    IN    @{Port_List}
    \    Run Keyword And Ignore Error    Delete Port    ${portname}
    #    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM11
    #    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM12
    #    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM13
    #    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM21
    #    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM22
    #    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM23
    #    #Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM31
    #    Run Keyword And Ignore Error    Delete Port    Network1_Port1
    #    Run Keyword And Ignore Error    Delete Port    Network1_Port2
    #    Run Keyword And Ignore Error    Delete Port    Network1_Port3
    #    Run Keyword And Ignore Error    Delete Port    Network1_Port4
    #    Run Keyword And Ignore Error    Delete Port    Network1_Port5
    #    Run Keyword And Ignore Error    Delete Port    Network1_Port6
    #    Run Keyword And Ignore Error    Delete Port    Network1_Port7
    Run Keyword And Ignore Error    Update Router    Router1    --no-routes
    Run Keyword And Ignore Error    Remove Interface    Router1    Subnet1
    Run Keyword And Ignore Error    Delete Router    Router1
    #    Run Keyword And Ignore Error    Delete Bgpvpn    Vpn1
    Run Keyword And Ignore Error    Delete SubNet    Subnet1
    Run Keyword And Ignore Error    Delete Network    Network1
    Comment    "Delete ITM tunnel between DPNs"
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet_1}=    Set Variable    ${first_two_octets}.0.0/16
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_2_IP}    .    2
    ${subnet_2}=    Set Variable    ${first_two_octets}.0.0/16
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
    ${ActualRemoteBucketEntry}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
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
    \    Append To List    ${NextHopList}    destination=${ip}/${mask},gateway=${VmIp}
    [Return]    @{NextHopList}

Configure Next Hop on Router
    [Arguments]    ${val}    ${VmList1}    ${VmList2}    ${mask}
    [Documentation]    Key word for updating Next Hop Routes
    @{NextHopList_1}    Generate Next Hop    ${staticip}    ${mask}    @{VmList1}
    @{NextHopList_2}    Run Keyword if    ${val}==${2}    Generate Next Hop    ${staticip2}    ${mask}    @{VmList2}

    ${routes1}    catenate    --route    @{NextHopList_1}
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
    ${resp}    Execute Command on VM Instance    ${NetName}    ${VmIp}    sudo ifconfig eth0:0
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
    #Verify Static Ip Configured In VM
    #    [Arguments]    ${VM_IP}    ${NetName}    ${StaticIp}
    #    ${resp}    Execute Command on VM Instance    ${NetName}    ${VM_IP}    sudo ifconfig eth0:0
    #    Should Contain    ${resp}    ${StaticIp}
    #
    #Verify ECMP flows in Compute Node
    #    [Arguments]    ${ip}    ${ExpectedLocalBucketCount}    ${ExpectedRemoteBucketCount}    ${StaticIp}
    #
    #    ${OvsFlow}    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${OvsGroup}    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    #
    #    ${match}    ${ECMPgrp}    Should Match Regexp    ${OvsFlow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroup}    Should Match Regexp    ${OvsGroup}    group_id=${ECMPgrp}.*
    #    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #    Length Should Be    ${bucketCount}    ${ExpectedLocalBucketCount}
    #    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #    Length Should Be    ${RemoteVmBucket}    ${ExpectedRemoteBucketCount}
    #
    #Verify Packet Count after Ping
    #    [Arguments]    ${ip}    ${StaticIp}
    #
    #    ${OvsFlow}    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    #    ${OvsGroupStat}    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    #
    #    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${OvsFlow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    #    ${EcmpGroupStat}    Should Match Regexp    ${OvsGroupStat}    group_id=${ECMPgrp}.*
    #    ${PacketCount}    Get Regexp Matches    ${EcmpGroupStat}    bucket(\\d+):packet_count=(\\d+)
    #    Log    ${PacketCount}

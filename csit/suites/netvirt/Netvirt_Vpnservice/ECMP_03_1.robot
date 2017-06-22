*** Settings ***
Documentation     Test suite for ECMP(US-263.3.1) Verify traffic splitting on L3VPN within DC across VMs located on different CSSs
Suite Setup       Pre Setup
Suite Teardown    Clear Setup
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot    
Resource          ${CURDIR}/../../../libraries/VpnOperations.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OpenStackOperations.robot
Resource          ${CURDIR}/../../../libraries/OVSDB.robot
Library           OperatingSystem

*** Variables ***
${fail_resp}      0
${StaticIp}       100.100.100.100

*** Testcases ***
TC01 Verify Distribution of traffic with weighted buckets-3 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify The CSC should support ECMP traffic splitting on L3VPN within DC across VMs located on different CSSs - Distribution of traffic with weighted buckets-3 VM on CSS1,2 VM on CSS2
    Log    Update the Router with ECMP Route
    ${RouterUpdateCmd}    Set Variable    --routes type=dict list=true destination=${StaticIp}/32,nexthop=${VM_IPs[0]} destination=${StaticIp}/32,nexthop=${VM_IPs[1]} destination=${StaticIp}/32,nexthop=${VM_IPs[2]} destination=${StaticIp}/32,nexthop=${VM_IPs[3]} destination=${StaticIp}/32,nexthop=${VM_IPs[4]}
    Update Router    Router1    ${RouterUpdateCmd}
    Comment    Configure StaticIp on VMs
    Wait Until Keyword Succeeds    100s    20s    Run Keywords
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[0]}    sudo ifconfig eth0:0 ${StaticIp}/24 up    AND
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[1]}    sudo ifconfig eth0:0 ${StaticIp}/24 up    AND
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[2]}    sudo ifconfig eth0:0 ${StaticIp}/24 up    AND
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[3]}    sudo ifconfig eth0:0 ${StaticIp}/24 up    AND
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[4]}    sudo ifconfig eth0:0 ${StaticIp}/24 up
    Comment    Verify Static IP got configured on VMs
    Verify Static Ip Configured In VM    ${VM_IPs[0]}    Network1    ${StaticIp}
    Verify Static Ip Configured In VM    ${VM_IPs[1]}    Network1    ${StaticIp}
    Verify Static Ip Configured In VM    ${VM_IPs[2]}    Network1    ${StaticIp}
    Verify Static Ip Configured In VM    ${VM_IPs[3]}    Network1    ${StaticIp}
    Verify Static Ip Configured In VM    ${VM_IPs[4]}    Network1    ${StaticIp}
    Debug
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    Log    Verify the flow for Co-located ECMP route
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${3}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${2}
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${2}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${3}
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    ...    ELSE    Evaluate    ${fail_resp}+1
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    Should Be Equal    ${fail_resp}    ${0}    

TC02 Verify The ECMP flow should be added into all CSSs that have the footprint of the L3VPN and hosting Nexthop VM
    [Documentation]    Verify The ECMP flow should be added into all CSSs that have the footprint of the L3VPN and hosting Nexthop VM

    Log    Verify the ECMP flow in switch3
    ${Ovs3Flow}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs3Group}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int

    ${match}    Should Not Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}

    Create Vm Instance With Port On Compute Node    Network1_Port7    NOVA_VM31    ${OS_COMPUTE_3_IP}
	@{Vm31List}    Create List    NOVA_VM31
    ${VM31_IP}    ${DHCP_IP}    Collect VM IP Addresses    false    @{Vm31List}
    Append To List    ${VM_IPs}    ${VM31_IP[0]}
    
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    Should Match Regexp    ${CtrlFib}     ${VM31_IP[0]}\/32\\s+${OS_COMPUTE_3_IP}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs3Flow}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs3Group}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs3GroupStat}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int

    Log    Verify the flow for Co-located ECMP route
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${3}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${2}

    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${2}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${3}

    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs3Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${0}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${5}

    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM31    ${VMInstanceDict.NOVA_VM31}    ${OS_COMPUTE_3_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Log    Delete VM (NOVA_VM31) from DPN3
    Delete Vm Instance    NOVA_VM31
    Sleep    ${10}
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Not Match Regexp    ${CtrlFib}     ${VM31_IP[0]}\/32\\s+${OS_COMPUTE_3_IP}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs3Flow}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs3Group}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs3GroupStat}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int

    Comment    Verify flow got removed from DPN3
    ${match}    ${ECMPgrp}    Should Not Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)

    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1
    Should Be Equal    ${fail_resp}    ${0}

    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs3GroupStat}    Run Command On Remote System    ${OS_COMPUTE_3_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int

    Should Be Equal    ${fail_resp}    ${0}

TC03 Verify Distribution of traffic with weighted buckets - 2 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify Distribution of traffic with weighted buckets - 2 VM on CSS1 , 2 VM on CSS2
    Log    Update the Router with ECMP Route
    ${RouterUpdateCmd}    Set Variable    --routes type=dict list=true destination=${StaticIp}/32,nexthop=${VM_IPs[0]} destination=${StaticIp}/32,nexthop=${VM_IPs[1]} destination=${StaticIp}/32,nexthop=${VM_IPs[3]} destination=${StaticIp}/32,nexthop=${VM_IPs[4]}
    Update Router    Router1    ${RouterUpdateCmd}
    Wait Until Keyword Succeeds    100s    20s    Run Keywords
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[0]}    sudo ifconfig eth0:0 ${StaticIp}/24 up    AND
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[1]}    sudo ifconfig eth0:0 ${StaticIp}/24 up    AND
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[3]}    sudo ifconfig eth0:0 ${StaticIp}/24 up    AND
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[4]}    sudo ifconfig eth0:0 ${StaticIp}/24 up

    Comment    Verify Static IP got configured on VMs
    Verify Static Ip Configured In VM    ${VM_IPs[0]}    Network1    ${StaticIp}
    Verify Static Ip Configured In VM    ${VM_IPs[1]}    Network1    ${StaticIp}
    Verify Static Ip Configured In VM    ${VM_IPs[3]}    Network1    ${StaticIp}
    Verify Static Ip Configured In VM    ${VM_IPs[4]}    Network1    ${StaticIp}
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    Log    Verify the flow for Co-located ECMP route
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${2}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${1}
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${1}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${2}
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    ...    ELSE    Evaluate    ${fail_resp}+1
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    Log    Delete a VM (NOVA_VM12) from DPN1
    Delete Vm Instance    NOVA_VM12
    Sleep    10
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    Should Not Match Regexp    ${CtrlFib}    ${VM_IPs[1]}\/32\\s+${OS_COMPUTE_1_IP}
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    Log    Verify the flow for Co-located ECMP route
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${1}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${1}
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${1}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${1}
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    ...    ELSE    Evaluate    ${fail_resp}+1
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${match}    ${PacketCount}    ${ECMP1grp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMP1grp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    Log    Delete another VM (NOVA_VM11) from DPN1
    Delete Vm Instance    NOVA_VM11
    Sleep    10
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Not Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    Should Not Match Regexp    ${CtrlFib}    ${VM_IPs[0]}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    Log    Verify the flow for Co-located ECMP route
    ${match}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*resubmit\\(,220
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMP1grp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${0}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${1}
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${1}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${0}
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    ...    ELSE    Evaluate    ${fail_resp}+1
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    Should Be Equal    ${fail_resp}    ${0}

TC04 Verify Distribution of traffic with weighted buckets - Add VM on CSS1
    [Documentation]    263.3.2 Verify Distribution of traffic with weighted buckets - Add VM on CSS1
    Log    Create the VMs on DPN1configured as next-hop
    Create Vm Instance With Port On Compute Node    Network1_Port1    NOVA_VM11    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    100s    20s    Run Keyword
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[0]}    sudo ifconfig eth0:0 ${StaticIp}/24 up

    Comment    Verify Static IP got configured on VMs
    Verify Static Ip Configured In VM    ${VM_IPs[0]}    Network1    ${StaticIp}
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    #Should Not Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${VM_IPs[0]}\/32\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/32\\s+${OS_COMPUTE_2_IP}
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    Log    Verify the flow for Co-located ECMP route
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #Length Should Be    ${bucketCount}    ${1}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #Length Should Be    ${RemoteVmBucket}    ${1}
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #Length Should Be    ${bucketCount}    ${1}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #Length Should Be    ${RemoteVmBucket}    ${1}
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    ...    ELSE    Evaluate    ${fail_resp}+1
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    Comment    Create an VM on Switch1
    Create Vm Instance With Port On Compute Node    Network1_Port2    NOVA_VM12    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    100s    20s    Run Keyword
    ...    Execute Command on VM Instance    Network1    ${VM_IPs[1]}    sudo ifconfig eth0:0 ${StaticIp}/24 up

    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1Group}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs2Group}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    Log    Verify the flow for Co-located ECMP route
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #Length Should Be    ${bucketCount}    ${2}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #Length Should Be    ${RemoteVmBucket}    ${1}
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    #Length Should Be    ${bucketCount}    ${1}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    #Length Should Be    ${RemoteVmBucket}    ${2}
    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on VM Instance    Network1    ${VM_IPs[5]}    ping ${StaticIp} -c 15
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0
    ...    ELSE    Evaluate    ${fail_resp}+1
    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs2Flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${Ovs1GroupStat}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${Ovs2GroupStat}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)
    Should Be Equal    ${fail_resp}    ${0}    

*** Keywords ***
Pre Setup
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet_1}=    Set Variable    ${first_two_octets}.0.0/16
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_2_IP}    .    2
    ${subnet_2}=    Set Variable    ${first_two_octets}.0.0/16
    Comment    "Configure ITM tunnel between DPNs"
    ${Dpn1Id}    Get DPID    ${OS_COMPUTE_1_IP}
    ${Dpn2Id}    Get DPID    ${OS_COMPUTE_2_IP}
    #${Dpn3Id}    Get DPID    ${OS_COMPUTE_3_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    #${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
    Issue Command On Karaf Console    tep:add ${Dpn1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:add ${Dpn2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_2} null TZA
    #Issue Command On Karaf Console    tep:add ${Dpn3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_2} null TZA
    Issue Command On Karaf Console    tep:commit
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Comment    "Create Neutron Network , Subnet and Ports"
    Create Network    Network1
    Create SubNet    Network1    Subnet1    10.10.1.0/24
    Create Neutron Port With Additional Params    Network1    Network1_Port1    
    Create Neutron Port With Additional Params    Network1    Network1_Port2    
    Create Neutron Port With Additional Params    Network1    Network1_Port3    
    Create Neutron Port With Additional Params    Network1    Network1_Port4    
    Create Neutron Port With Additional Params    Network1    Network1_Port5    
    Create Neutron Port With Additional Params    Network1    Network1_Port6    
    Create Neutron Port With Additional Params    Network1    Network1_Port7    
    Log To Console    "Creating VM on switch 1"
    Create Vm Instance With Port On Compute Node    Network1_Port1    NOVA_VM11    ${OS_COMPUTE_1_IP}    
    Create Vm Instance With Port On Compute Node    Network1_Port2    NOVA_VM12    ${OS_COMPUTE_1_IP}    
    Create Vm Instance With Port On Compute Node    Network1_Port3    NOVA_VM13    ${OS_COMPUTE_1_IP}    
    Log To Console    "Creating VM on switch 2"
    Create Vm Instance With Port On Compute Node    Network1_Port4    NOVA_VM21    ${OS_COMPUTE_2_IP}    
    Create Vm Instance With Port On Compute Node    Network1_Port5    NOVA_VM22    ${OS_COMPUTE_2_IP}    
    Create Vm Instance With Port On Compute Node    Network1_Port6    NOVA_VM23    ${OS_COMPUTE_2_IP}    
    #Create Vm Instance With Port On Compute Node    Network1_Port7    NOVA_VM31    ${OS_COMPUTE_3_IP}   
    Comment    Create Routers
    Create Router    Router1
    #Comment    Create BgpVpn
    #${Additional_Args}    Set Variable    -- --route-distinguishers list=true 100:10 100:11 100:12 100:13 100:14 --route-targets 100:1
    #${vpnid}    Create Bgpvpn    Vpn1    ${Additional_Args}
    Comment    Add Networks to Neutron Router and Associate To L3vpn
    Comment    "Associate Subnet1 to Router1"
    Add Router Interface    Router1    Subnet1
    #Log    "Associate Router1 to VPN1"
    #Bgpvpn Router Associate    Router1    Vpn1
    @{VmList}    Create List    NOVA_VM11    NOVA_VM12    NOVA_VM13    NOVA_VM21    NOVA_VM22
    ...    NOVA_VM23
    Set Global Variable    ${VmList}
    ${VM_IPs}    ${DHCP_IP}    Collect VM IP Addresses    false    @{VmList}
    Set Global Variable    ${VM_IPs}
    Log    ${VM_IPs}

Clear Setup
    [Documentation]    Clean the config created for ECMP TCs
    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM11
    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM12
    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM13
    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM21
    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM22
    Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM23
    #Run Keyword And Ignore Error    Delete Vm Instance    NOVA_VM31
    Run Keyword And Ignore Error    Delete Port    Network1_Port1
    Run Keyword And Ignore Error    Delete Port    Network1_Port2
    Run Keyword And Ignore Error    Delete Port    Network1_Port3
    Run Keyword And Ignore Error    Delete Port    Network1_Port4
    Run Keyword And Ignore Error    Delete Port    Network1_Port5
    Run Keyword And Ignore Error    Delete Port    Network1_Port6
    Run Keyword And Ignore Error    Delete Port    Network1_Port7
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
    #${Dpn3Id}    Get DPID    ${OS_COMPUTE_3_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    #${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
    Issue Command On Karaf Console    tep:delete ${Dpn1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
    Issue Command On Karaf Console    tep:delete ${Dpn2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_2} null TZA
    #Issue Command On Karaf Console    tep:delete ${Dpn3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_2} null TZA
    Issue Command On Karaf Console    tep:commit

Verify Static Ip Configured In VM
    [Arguments]    ${VM_IP}    ${NetName}    ${StaticIp}
    ${resp}    Execute Command on VM Instance    ${NetName}    ${VM_IP}    sudo ifconfig eth0:0
    Should Contain    ${resp}    ${StaticIp}

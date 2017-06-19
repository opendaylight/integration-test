#Script header:
#       $Id: SF623.1: ECMP Support for L3VPN tests
#Name:
#       SF623.1: ECMP Support for L3VPN
#Purpose :
#       Verify ECMP Support by ODL Controller 
#Author:
#       Ravi Ranjan ---(ravi.ranjan3@tcs.com)
#Maintainer:
#       Ravi Ranjan ---(ravi.ranjan3@tcs.com)
#
#References:
#       ECMP Support for L3VPN Testplan
#
#Description:
#
#
#Known Bugs:
#
#Script status:
#       Production
#
#TEST TOPOLOGY
#       Refer the Topology Section
#
# End of Header
#=============================================================================================================
*** Settings ***
Documentation     Test suite for ECMP(US-263.3.1) Verify traffic splitting on L3VPN within DC across VMs located on different CSSs
Suite Setup        Pre Setup
Suite Teardown     Clear Setup
#Test Setup         Pretest Setup
#Test Teardown      Pretest Cleanup
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/VpnOperations.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OpenStackOperations.robot
Resource          ${CURDIR}/../../../libraries/SwitchOperations.robot
#Library           DebugLibrary

*** Variables ***
${fail_resp}      0
${StaticIp}    100.100.100.100
${SGP}         CUSTM_SGP

*** Testcases ***
Verify Distribution of traffic with weighted buckets-3 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify The CSC should support ECMP traffic splitting on L3VPN within DC across VMs located on different CSSs - Distribution of traffic with weighted buckets-3 VM on CSS1,2 VM on CSS2

    Log    Update the Router with ECMP Route
    ${RouterUpdateCmd}    Set Variable    --routes type=dict list=true destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM11} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM12} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM13} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM21} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM22}
    Update Router    Router1    ${RouterUpdateCmd}
    Comment    Configure StaticIp on VMs
    Wait Until Keyword Succeeds    100s    20s    Run Keywords
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM11    ${VMInstanceDict.NOVA_VM11}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM12    ${VMInstanceDict.NOVA_VM12}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM13    ${VMInstanceDict.NOVA_VM13}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM21    ${VMInstanceDict.NOVA_VM21}    ${OS_COMPUTE_2_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM22    ${VMInstanceDict.NOVA_VM22}    ${OS_COMPUTE_2_IP}

    Comment    Verify Static IP got configured on VMs
    Verify Static Ip Configured In VM    NOVA_VM11    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM12    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM13    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM21    ${OS_COMPUTE_2_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM22    ${OS_COMPUTE_2_IP}    ${StaticIp}

    Debug
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}

    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

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
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    Should Be Equal    ${fail_resp}    ${0}

#Verify The ECMP flow should be added into all CSSs that have the footprint of the L3VPN and hosting Nexthop VM
#    [Documentation]    Verify The ECMP flow should be added into all CSSs that have the footprint of the L3VPN and hosting Nexthop VM
#
#    Log    Verify the ECMP flow in switch3
#    ${Ovs3Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_3_IP}    br-int
#    ${Ovs3Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_3_IP}    br-int
#
#    ${match}    Should Not Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}
#
#    Log    Create NOVA_VM31 on Dpn3
#    Create Vm Instance With Port On Compute Node    Network1_Port7    NOVA_VM31    ${OS_COMPUTE_3_IP}    ${image}    ${flavor}    CUSTM_SGP
#    ${InstanceId}    OpenStackOperations.Get VM Instance    NOVA_VM31
#    Set To Dictionary    ${VMInstanceDict}    NOVA_VM31=${InstanceId}
#    ${VmIp}    OpenStackOperations.Get VM IP     NOVA_VM31
#    ${stripped}    Strip String    ${VmIp[0]}    characters=','
#    Set To Dictionary    ${VmIpDict}    NOVA_VM31=${stripped}
#
#    Log    Verify the Routes in controller
#    ${CtrlFib}    Issue Command On Karaf Console    fib-show
#    Log    ${CtrlFib}
#    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
#    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}
#    Should Match Regexp    ${CtrlFib}     ${VmIpDict.NOVA_VM31}\/32\\s+${TunnelSourceIp[2]}
#
#    Log    Verify the ECMP flow in switch
#    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
#    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
#    ${Ovs3Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_3_IP}    br-int
#    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
#    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
#    ${Ovs3Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_3_IP}    br-int
#    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
#    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int
#    ${Ovs3GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_3_IP}    br-int
#
#    Log    Verify the flow for Co-located ECMP route
#    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
#    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
#    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
#    Length Should Be    ${bucketCount}    ${3}
#    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
#    Length Should Be    ${RemoteVmBucket}    ${2}
#
#    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
#    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
#    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
#    Length Should Be    ${bucketCount}    ${2}
#    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
#    Length Should Be    ${RemoteVmBucket}    ${3}
#
#    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
#    ${EcmpGroup}    Should Match Regexp    ${Ovs3Group}    group_id=${ECMPgrp}.*
#    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
#    Length Should Be    ${bucketCount}    ${0}
#    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
#    Length Should Be    ${RemoteVmBucket}    ${5}
#
#    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
#    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM31    ${VMInstanceDict.NOVA_VM31}    ${OS_COMPUTE_3_IP}
#    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
#    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1
#
#    Log    Delete VM (NOVA_VM31) from DPN3
#    Delete Vm Instance    NOVA_VM31
#    Sleep    ${10} 
#    Log    Verify the Routes in controller
#    ${CtrlFib}    Issue Command On Karaf Console    fib-show
#    Log    ${CtrlFib}
#    Should Not Match Regexp    ${CtrlFib}     ${VmIpDict.NOVA_VM31}\/32\\s+${TunnelSourceIp[2]}
#
#    Log    Verify the ECMP flow in switch
#    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
#    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
#    ${Ovs3Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_3_IP}    br-int
#    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
#    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
#    ${Ovs3Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_3_IP}    br-int
#    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
#    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int
#    ${Ovs3GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_3_IP}    br-int
#
#    Comment    Verify flow got removed from DPN3
#    ${match}    ${ECMPgrp}    Should Not Match Regexp    ${Ovs3Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
#
#    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
#    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
#    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
#    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1
#    Should Be Equal    ${fail_resp}    ${0}
#
#    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
#    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int
#    ${Ovs3GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_3_IP}    br-int
#
#    Should Be Equal    ${fail_resp}    ${0}


Verify Distribution of traffic with weighted buckets - 2 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify Distribution of traffic with weighted buckets - 2 VM on CSS1 , 2 VM on CSS2
    Log    Update the Router with ECMP Route
    ${RouterUpdateCmd}    Set Variable    --routes type=dict list=true destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM11} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM12} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM21} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM22}
    Update Router    Router1    ${RouterUpdateCmd}

    Wait Until Keyword Succeeds    100s    20s    Run Keywords
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM11    ${VMInstanceDict.NOVA_VM11}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM12    ${VMInstanceDict.NOVA_VM12}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM21    ${VMInstanceDict.NOVA_VM21}    ${OS_COMPUTE_2_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM22    ${VMInstanceDict.NOVA_VM22}    ${OS_COMPUTE_2_IP}

    Comment    Verify Static IP got configured on VMs
    Verify Static Ip Configured In VM    NOVA_VM11    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM12    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM21    ${OS_COMPUTE_2_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM22    ${OS_COMPUTE_2_IP}    ${StaticIp}


    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

    Log    Verify the flow for Co-located ECMP route
    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${2}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${2}

    ${match}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2Group}    group_id=${ECMPgrp}.*
    ${bucketCount}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=group:(\\d+)
    Length Should Be    ${bucketCount}    ${2}
    ${RemoteVmBucket}    Get Regexp Matches    ${EcmpGroup}    bucket=actions=resubmit
    Length Should Be    ${RemoteVmBucket}    ${2}

    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    Should Be Equal    ${fail_resp}    ${0}

Verify Distribution of traffic with weighted buckets - 3 VM on CSS1 , 1 VM on CSS2 - Delete VM on CSS1
    [Documentation]    263.3.2 Verify Distribution of traffic with weighted buckets - 3 VM on CSS1 , 1 VM on CSS2 - Delete VM on CSS1
    Log    Update the Router with ECMP Route
    ${RouterUpdateCmd}    Set Variable    --routes type=dict list=true destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM11} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM12} destination=${StaticIp}/32,nexthop=${VmIpDict.NOVA_VM21}

    #Update Router    Router1    --no-routes
    #Sleep    ${5}
    Update Router    Router1    ${RouterUpdateCmd}

    Wait Until Keyword Succeeds    100s    20s    Run Keywords
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM11    ${VMInstanceDict.NOVA_VM11}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM12    ${VMInstanceDict.NOVA_VM13}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM21    ${VMInstanceDict.NOVA_VM21}    ${OS_COMPUTE_2_IP} 

    Comment    Verify Static IP got configured on VMs
    Verify Static Ip Configured In VM    NOVA_VM11    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM13    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM21    ${OS_COMPUTE_2_IP}    ${StaticIp}

    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

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
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    Log    Delete a VM (NOVA_VM13) from DPN1
    Delete Vm Instance    NOVA_VM12
    Sleep    10
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}
    Should Not Match Regexp    ${CtrlFib}     ${VmIpDict.NOVA_VM12}\/32\\s+${TunnelSourceIp[0]}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

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
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

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
    Should Not Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
    Should Not Match Regexp    ${CtrlFib}     ${VmIpDict.NOVA_VM11}\/32\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

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
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    Should Be Equal    ${fail_resp}    ${0}

Verify Distribution of traffic with weighted buckets - Add VM on CSS1
    [Documentation]    263.3.2 Verify Distribution of traffic with weighted buckets - Add VM on CSS1
    Log    Create the VMs on DPN1configured as next-hop
    Create Vm Instance With Port On Compute Node    Network1_Port1    NOVA_VM11    ${OS_COMPUTE_1_IP}    ${image}    ${flavor}
    ${InstanceId}    OpenStackOperations.Get VM Instance    NOVA_VM11
    Set To Dictionary    ${VMInstanceDict}    NOVA_VM11=${InstanceId}
    ${VmIp}    OpenStackOperations.Get VM IP    NOVA_VM11
    ${stripped}    Strip String    ${VmIp[0]}    characters=','
    Set To Dictionary    ${VmIpDict}    NOVA_VM11=${stripped}

    Wait Until Keyword Succeeds    100s    20s    Run Keywords
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM11    ${VMInstanceDict.NOVA_VM11}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM21    ${VMInstanceDict.NOVA_VM21}    ${OS_COMPUTE_2_IP}

    Comment    Verify Static IP got configured on VMs
    Verify Static Ip Configured In VM    NOVA_VM11    ${OS_COMPUTE_1_IP}    ${StaticIp}
    Verify Static Ip Configured In VM    NOVA_VM21    ${OS_COMPUTE_2_IP}    ${StaticIp}

    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    #Should Not Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CtrlFib}     ${VmIpDict.NOVA_VM11}\/32\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

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
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    Create Vm Instance With Port On Compute Node    Network1_Port2    NOVA_VM12    ${OS_COMPUTE_1_IP}    ${image}    ${flavor}
    ${InstanceId}    OpenStackOperations.Get VM Instance    NOVA_VM12
    Set To Dictionary    ${VMInstanceDict}    NOVA_VM12=${InstanceId}
    ${VmIp}    OpenStackOperations.Get VM IP    NOVA_VM12
    ${stripped}    Strip String    ${VmIp[0]}    characters=','
    Set To Dictionary    ${VmIpDict}    NOVA_VM12=${stripped}

    Wait Until Keyword Succeeds    100s    20s    Run Keywords
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM11    ${VMInstanceDict.NOVA_VM11}    ${OS_COMPUTE_1_IP}    AND
    ...    Execute Command on server    sudo ifconfig eth0:0 ${StaticIp}/24 up    NOVA_VM12    ${VMInstanceDict.NOVA_VM12}    ${OS_COMPUTE_1_IP}

    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Group}    SwitchOperations.SW_GET_FLOW_GROUP     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

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
    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Log    Verify the ECMP flow in switch
    ${Ovs1Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2Flow}    SwitchOperations.SW_GET_FLOW_TABLE     ${OS_COMPUTE_2_IP}    br-int
    ${Ovs1GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_1_IP}    br-int
    ${Ovs2GroupStat}    SwitchOperations.SW_GET_GROUP_STAT     ${OS_COMPUTE_2_IP}    br-int

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs1Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs1GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    ${match}    ${PacketCount}    ${ECMPgrp}    Should Match Regexp    ${Ovs2Flow}    table=21.*n_packets=(\\d+).*nw_dst=${StaticIp}.*group:(\\d+)
    ${EcmpGroup}    Should Match Regexp    ${Ovs2GroupStat}    group_id=${ECMPgrp}.*
    ${PacketCount}    Get Regexp Matches    ${EcmpGroup}    bucket(\\d+):packet_count=(\\d+)

    Should Be Equal    ${fail_resp}    ${0}

#Verify Distribution of traffic with weighted buckets - delete/create vpn
#    [Documentation]    Verify Distribution of traffic with weighted buckets - delete/create vpn
#    Log    Delete the Vpn1 and verify the traffic
#    Delete Bgpvpn    Vpn1
#
#    Sleep    ${10}
#    Log    Verify the Routes in controller
#    ${CtrlFib}    Issue Command On Karaf Console    fib-show
#    Log    ${CtrlFib}
#    #Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
#    #Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}
#
#    Log    Verify the ECMP flow in switch
#    ${OvsFlow}    SwitchOperations.SW_DUMP_ALL_TABLES     ${OS_COMPUTE_1_IP}    br-int
#    ${OvsFlow}    SwitchOperations.SW_DUMP_ALL_TABLES     ${OS_COMPUTE_2_IP}    br-int
#
#    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
#    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
#    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
#    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1
#
#    Log    Create the Vpn1 and verify the traffic
#    ${Additional_Args}    Set Variable   -- --route-distinguishers list=true 100:10 100:11 100:12 100:13 100:14 --route-targets 100:1
#    Create Bgpvpn    Vpn1    ${Additional_Args}
#
#    Log    Verify the Routes in controller
#    ${CtrlFib}    Issue Command On Karaf Console    fib-show
#    Log    ${CtrlFib}
#
#    Log    Verify the ECMP flow in switch
#    ${OvsFlow}    SwitchOperations.SW_DUMP_ALL_TABLES     ${OS_COMPUTE_1_IP}    br-int
#    ${OvsFlow}    SwitchOperations.SW_DUMP_ALL_TABLES     ${OS_COMPUTE_2_IP}    br-int
#
#    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
#    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
#    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
#    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1
#
#
#    Log To Console    Associate Network/Router to Vpn1
#    Bgpvpn Router Associate    Router1    Vpn1
#
#    Sleep    ${10}
#    Log    Verify the Routes in controller
#    ${CtrlFib}    Issue Command On Karaf Console    fib-show
#    Log    ${CtrlFib}
#    #Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[0]}
#    #Should Match Regexp    ${CtrlFib}     ${StaticIp}\/32\\s+${TunnelSourceIp[1]}
#
#    Log    Verify the ECMP flow in switch
#    ${OvsFlow}    SwitchOperations.SW_DUMP_ALL_TABLES     ${OS_COMPUTE_1_IP}    br-int
#    ${OvsFlow}    SwitchOperations.SW_DUMP_ALL_TABLES     ${OS_COMPUTE_2_IP}    br-int
#
#    Log    Verify the traffic originated from VM getting splitted between nexthop-VMs
#    ${pingresp}    Execute Command on server    ping ${StaticIp} -c 15    NOVA_VM23    ${VMInstanceDict.NOVA_VM23}    ${OS_COMPUTE_2_IP}
#    ${match}    ${grp1}    Should Match Regexp    ${pingresp}    (\\d+)\\% packet loss
#    ${fail_resp}    Run Keyword If    ${grp1}<=${20}    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1
#    Should Be Equal    ${fail_resp}    ${0}

*** Keywords ***
Pre Setup
    Comment    "Configure ITM tunnel between DPNs"
    ${Dpn1Id}    SW_GET_SWITCH_ID    ${OS_COMPUTE_1_IP}    br-int
    ${Dpn2Id}    SW_GET_SWITCH_ID    ${OS_COMPUTE_2_IP}    br-int
    #${Dpn3Id}    SW_GET_SWITCH_ID    ${OS_COMPUTE_3_IP}    br-int
    Issue Command On Karaf Console    tep:add ${Dpn1Id} dpdk0 0 ${TunnelSourceIp[0]} ${TunnelNetwork} null TZA
    Issue Command On Karaf Console    tep:add ${Dpn2Id} dpdk0 0 ${TunnelSourceIp[1]} ${TunnelNetwork} null TZA
    #Issue Command On Karaf Console    tep:add ${Dpn3Id} dpdk0 0 ${TunnelSourceIp[2]} ${TunnelNetwork} null TZA
    Issue Command On Karaf Console    tep:commit
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}


    Comment    "Creating customised security Group"
    ${OUTPUT}     ${SGP_ID}    OpenStackOperations.Neutron Security Group Create     ${SGP}
    Set Global Variable    ${SGP_ID}

    Comment    "Creating the rules for ingress direction"
    ${OUTPUT1}    ${RULE_ID1}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}   direction=ingress    protocol=icmp
    ${OUTPUT2}    ${RULE_ID2}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}   direction=ingress    protocol=tcp
    ${OUTPUT3}    ${RULE_ID3}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}   direction=ingress    protocol=udp

    Comment    "Creating the rules for egress direction"
    ${OUTPUT4}    ${RULE_ID4}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}   direction=egress    protocol=icmp
    ${OUTPUT5}    ${RULE_ID5}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}   direction=egress    protocol=tcp
    ${OUTPUT6}    ${RULE_ID6}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}   direction=egress    protocol=udp


    Comment    "Create Neutron Network , Subnet and Ports"
    Create Network    Network1
    Create SubNet    Network1    Subnet1    10.10.1.0/24
    ${ADD_ARG}    Catenate     --security-group    ${SGP}
    Create Neutron Port With Additional Params    Network1    Network1_Port1    ${ADD_ARG}
    Create Neutron Port With Additional Params    Network1    Network1_Port2    ${ADD_ARG}
    Create Neutron Port With Additional Params    Network1    Network1_Port3    ${ADD_ARG}
    Create Neutron Port With Additional Params    Network1    Network1_Port4    ${ADD_ARG}
    Create Neutron Port With Additional Params    Network1    Network1_Port5    ${ADD_ARG}
    Create Neutron Port With Additional Params    Network1    Network1_Port6    ${ADD_ARG}
    Create Neutron Port With Additional Params    Network1    Network1_Port7    ${ADD_ARG}

    Log To Console    "Creating NOVA_VM11"
    Create Vm Instance With Port On Compute Node    Network1_Port1    NOVA_VM11    ${OS_COMPUTE_1_IP}    ${image}    ${flavor}    CUSTM_SGP
    Log To Console    "Creating NOVA_VM12"
    Create Vm Instance With Port On Compute Node    Network1_Port2    NOVA_VM12    ${OS_COMPUTE_1_IP}    ${image}    ${flavor}    CUSTM_SGP
    Create Vm Instance With Port On Compute Node    Network1_Port3    NOVA_VM13    ${OS_COMPUTE_1_IP}    ${image}    ${flavor}    CUSTM_SGP
    Log To Console    "Creating NOVA_VM21"
    Create Vm Instance With Port On Compute Node    Network1_Port4    NOVA_VM21    ${OS_COMPUTE_2_IP}    ${image}    ${flavor}    CUSTM_SGP
    Log To Console    "Creating NOVA_VM22"
    Create Vm Instance With Port On Compute Node    Network1_Port5    NOVA_VM22    ${OS_COMPUTE_2_IP}    ${image}    ${flavor}    CUSTM_SGP

    Create Vm Instance With Port On Compute Node    Network1_Port6    NOVA_VM23    ${OS_COMPUTE_2_IP}    ${image}    ${flavor}    CUSTM_SGP
    #Create Vm Instance With Port On Compute Node    Network1_Port7    NOVA_VM31    ${OS_COMPUTE_3_IP}    ${image}    ${flavor}    CUSTM_SGP

    Comment    Create Routers
    Create Router    Router1

    Comment    Create BgpVpn
    ${Additional_Args}    Set Variable   -- --route-distinguishers list=true 100:10 100:11 100:12 100:13 100:14 --route-targets 100:1
    ${vpnid}    Create Bgpvpn     Vpn1    ${Additional_Args}

    Comment    Add Networks to Neutron Router and Associate To L3vpn
    Comment    "Associate Subnet1 to Router1"
    Add Router Interface    Router1    Subnet1

    Log    "Associate Router1 to VPN1"
    Bgpvpn Router Associate    Router1    Vpn1

    Log    Get the VM-instance and VM-Ip
    &{VMInstanceDict}    Create Dictionary
    &{VmIpDict}    Create Dictionary
    Set Global Variable    ${VMInstanceDict}
    Set Global Variable    ${VmIpDict}
    @{VmList}    Create List    NOVA_VM11    NOVA_VM12    NOVA_VM13    NOVA_VM21    NOVA_VM22    NOVA_VM23
    Set Global Variable    ${VmList}
    :For    ${VmName}    In    @{VmList}
    \    ${InstanceId}    OpenStackOperations.Get VM Instance    ${VmName}
    \    Set To Dictionary    ${VMInstanceDict}    ${VmName}=${InstanceId}
    \    ${VmIp}    OpenStackOperations.Get VM IP    ${VmName}
    \    ${stripped}    Strip String    ${VmIp[0]}    characters=','
    \    Set To Dictionary    ${VmIpDict}    ${VmName}=${stripped}


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
    Run Keyword And Ignore Error    Update Router    Router1   --no-routes
    Run Keyword And Ignore Error    Remove Interface    Router1    Subnet1
    Run Keyword And Ignore Error    Delete Router     Router1
    Run Keyword And Ignore Error    Delete Bgpvpn    Vpn1
    Run Keyword And Ignore Error    Delete SubNet    Subnet1
    Run Keyword And Ignore Error    Delete Network    Network1
    Run Keyword And Ignore Error    Neutron Security Group Delete    ${SGP}

    Comment    "Delete ITM tunnel between DPNs"
    ${Dpn1Id}    SW_GET_SWITCH_ID    ${OS_COMPUTE_1_IP}    br-int
    ${Dpn2Id}    SW_GET_SWITCH_ID    ${OS_COMPUTE_2_IP}    br-int
    #${Dpn3Id}    SW_GET_SWITCH_ID    ${OS_COMPUTE_3_IP}    br-int
    Issue Command On Karaf Console    tep:delete ${Dpn1Id} dpdk0 0 ${TunnelSourceIp[0]} ${TunnelNetwork} null TZA
    Issue Command On Karaf Console    tep:delete ${Dpn2Id} dpdk0 0 ${TunnelSourceIp[1]} ${TunnelNetwork} null TZA
    #Issue Command On Karaf Console    tep:delete ${Dpn3Id} dpdk0 0 ${TunnelSourceIp[2]} ${TunnelNetwork} null TZA
    Issue Command On Karaf Console    tep:commit

Verify Static Ip Configured In VM
    [Arguments]    ${VmName}    ${DpnIp}    ${StaticIp}
    ${resp}    Execute Command on server    sudo ifconfig eth0:0    ${VmName}    ${VMInstanceDict.${VmName}}    ${DpnIp}
    Should Contain    ${resp}    ${StaticIp}


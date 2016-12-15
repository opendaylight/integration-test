*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       Setup SXP Cluster Session
Suite Teardown    Clean SXP Cluster Session
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        2
${MAC_ADDRESS_TABLE}    &{EMPTY}
${VIRTUAL_IP}     192.168.50.16
${VIRTUAL_INTERFACE}    eth1:0
${VIRTUAL_IP_MASK}    255.255.255.0

*** Test Cases ***
Setup Demo
    [Documentation]    Test SXP connection switchover only if Controller with SCS is isolated
    ${controller_index}    Get Active Controller
    ${route}    Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes}    Route Definitions Xml    ${route}
    Put Routing Configuration To Controller    ${routes}    controller${controller_index}
    Setup Custom SXP Cluster    ${VIRTUAL_IP}    listener    version4

Isolate Active Follower
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    ${controller_index}    Get Active Controller
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}

Un Isolate Active Follower
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    ${controller_index}    Get Active Controller
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}

Add Bindings To Cluster
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    ${active_follower}    Get Active Controller
    : FOR    ${i}    IN RANGE    1    10
    \    Add Binding    ${i}0    ${i}.${i}.${i}.${i}/32    node=${CLUSTER_NODE_ID}    session=controller${active_follower}

Clean Demo
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    Clean SXP Cluster
    ${any_follower}    Get Any Controller
    Clean Routing Configuration To Controller    controller${any_follower}

*** Keywords ***
Setup Custom SXP Cluster
    [Arguments]    ${peer_address}    ${peer_mode}    ${version}=version4
    [Documentation]    Setup and connect SXP cluster topology
    Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    20    1    Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}    system=${TOOLS_SYSTEM_IP}
    ...    ip=${EMPTY}
    ${cluster_mode}    Get Opposing Mode    ${peer_mode}
    Add Connection    ${version}    ${peer_mode}    ${peer_address}    64999    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${controller_id}    Get Active Controller
    Add Node    ${CLUSTER_NODE_ID}    ip=${peer_address}    session=controller${controller_id}
    Wait Until Keyword Succeeds    20    1    Check Cluster Node started    ${CLUSTER_NODE_ID}
    Add Connection    ${version}    ${cluster_mode}    ${TOOLS_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    Wait Until Keyword Succeeds    120    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=controller${controller_id}
    ...    version=${version}

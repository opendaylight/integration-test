*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Test Setup        Setup Custom SXP Cluster    ${VIRTUAL_IP}
Test Teardown     Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        5
${MAC_ADDRESS_TABLE}    &{EMPTY}
${VIRTUAL_IP}     192.168.50.20
${VIRTUAL_INTERFACE}    eth1:0
${VIRTUAL_IP_MASK}    255.255.255.0

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    Test SXP connection switchover only if Controller with SCS is isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Setup Custom SXP Cluster Session
    Setup SXP Cluster Session
    ${mac_addresses}    Map Followers To Mac Addresses
    Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}
    ${route}    Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes}    Route Definitions Xml    ${route}
    ${any_follower}    Get Any Controller
    Put Routing Configuration To Controller    ${routes}    controller${any_follower}

Clean Custom SXP Cluster Session
    ${any_follower}    Get Any Controller
    Clean Routing Configuration To Controller    controller${any_follower}
    Clean SXP Cluster Session

Setup Custom SXP Cluster
    [Arguments]    ${peer_address}    ${peer_mode}=listener
    [Documentation]    Setup and connect SXP cluster topology
    Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    20    1    Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}    system=${TOOLS_SYSTEM_IP}
    ...    ip=${EMPTY}
    ${cluster_mode}    Get Opposing Mode    ${peer_mode}
    Add Connection    version4    ${peer_mode}    ${peer_address}    64999    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${controller_id}    Get Active Controller
    Add Node    ${CLUSTER_NODE_ID}    ip=${peer_address}    session=controller${controller_id}
    Wait Until Keyword Succeeds    20    1    Check Cluster Node started    ${CLUSTER_NODE_ID}
    Add Connection    version4    ${cluster_mode}    ${TOOLS_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    Wait Until Keyword Succeeds    120    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    session=controller${controller_id}

Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected afterwards reverts isolation
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${active_follower}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    ${VIRTUAL_IP}    session=${DEVICE_SESSION}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    ${VIRTUAL_IP}    session=${DEVICE_SESSION}

Check Device is Connected
    [Arguments]    ${node}    ${remote_ip}    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Checks if SXP device is connected to at least one cluster node
    ${resp}    Get Connections    node=${node}    session=${session}
    Should Contain Connection    ${resp}    ${remote_ip}    ${port}    any    ${version}

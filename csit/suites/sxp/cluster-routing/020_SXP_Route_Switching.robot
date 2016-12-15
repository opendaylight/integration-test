*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Test Teardown     Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        2
${MAC_ADDRESS_TABLE}    &{EMPTY}
${VIRTUAL_IP}     ${EMPTY}
${VIRTUAL_INTERFACE}    ${EMPTY}
${VIRTUAL_IP_MASK}    255.255.255.0

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    Test SXP connection switchover only if Controller with SCS is isolated
    Setup Custom SXP Cluster    ${VIRTUAL_IP}    listener
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}    listener

Isolation of SXP service follower Test Listener Part
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    ${controller_index}    Get Active Controller
    Setup Custom SXP Cluster    ${VIRTUAL_IP}    listener
    Setup SXP Cluster Bindings    ${CLUSTER_NODE_ID}    controller${controller_index}
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller With Bindings    ${controller_index}    ${DEVICE_NODE_ID}    listener    ${DEVICE_SESSION}

Isolation of SXP service follower Test Speaker Part
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    Setup Custom SXP Cluster    ${VIRTUAL_IP}    speaker
    Setup SXP Cluster Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller With Bindings    ${controller_index}    ${CLUSTER_NODE_ID}    speaker

*** Keywords ***
Setup Custom SXP Cluster Session
    Setup SXP Cluster Session
    ${controller_index}    Get Active Controller
    ${mac_addresses}    Map Followers To Mac Addresses
    Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}
    ${v_ip}    Generate Virtual Ip    ${ODL_SYSTEM_1_IP}
    Set Suite Variable    ${VIRTUAL_IP}    ${v_ip}
    ${v_interface}    Generate Virtual Interface    ${v_ip}    ${controller_index}
    Set Suite Variable    ${VIRTUAL_INTERFACE}    ${v_interface}
    ${route}    Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes}    Route Definitions Xml    ${route}
    Put Routing Configuration To Controller    ${routes}    controller${controller_index}

Clean Custom SXP Cluster Session
    ${any_follower}    Get Any Controller
    Clean Routing Configuration To Controller    controller${any_follower}
    Clean SXP Cluster Session

Setup Custom SXP Cluster
    [Arguments]    ${peer_address}    ${peer_mode}
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
    Wait Until Keyword Succeeds    120    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=controller${controller_id}

Setup SXP Cluster Bindings
    [Arguments]    ${node}    ${session}=${EMPTY}
    [Documentation]    Setup and connect SXP cluster topology
    : FOR    ${i}    IN RANGE    1    25
    \    Add Binding    ${i}0    ${i}.${i}.${i}.${i}/32    node=${node}    session=${session}

Isolate SXP Controller
    [Arguments]    ${controller_index}    ${peer_mode}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected afterwards reverts isolation
    ${cluster_mode}    Get Opposing Mode    ${peer_mode}
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${active_follower}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    ${VIRTUAL_IP}    ${peer_mode}
    ...    session=${DEVICE_SESSION}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    ${VIRTUAL_IP}    ${peer_mode}
    ...    session=${DEVICE_SESSION}

Isolate SXP Controller With Bindings
    [Arguments]    ${controller_index}    ${node}    ${peer_mode}    ${session}=${EMPTY}
    [Documentation]    Isolate one of cluster nodes and perform check that bindings were propagated afterwards reverts isolation
    ${find_session}    Set Variable If    '${session}' == '${EMPTY}'    ${True}    ${False}
    ${cluster_mode}    Get Opposing Mode    ${peer_mode}
    ${session}    Set Variable If    ${find_session}    controller${controller_index}    ${session}
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${active_follower}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    ${VIRTUAL_IP}    ${peer_mode}
    ...    session=${DEVICE_SESSION}
    ${session}    Set Variable If    ${find_session}    controller${active_follower}    ${session}
    Wait Until Keyword Succeeds    30    1    Check Bindings    ${node}    ${session}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    ${VIRTUAL_IP}    ${peer_mode}
    ...    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    30    1    Check Bindings    ${node}    ${session}

Check Device is Connected
    [Arguments]    ${node}    ${remote_ip}    ${mode}=any    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Checks if SXP device is connected to at least one cluster node
    ${resp}    Get Connections    node=${node}    session=${session}
    Should Contain Connection    ${resp}    ${remote_ip}    ${port}    ${mode}    ${version}

Check Bindings
    [Arguments]    ${node}    ${session}
    [Documentation]    Checks that bindings were propagated to Peer
    ${resp}    Get Bindings    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    1    25
    \    Should Contain Binding    ${resp}    ${i}0    ${i}.${i}.${i}.${i}/32

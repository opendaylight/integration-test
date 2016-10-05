*** Settings ***
Documentation     Library containing Keywords used for SXP cluster testing
Library           RequestsLibrary
Library           ./Sxp.py
Resource          ./SxpLib.robot
Resource          ./ClusterManagement.robot
Variables         ../variables/Variables.py

*** Variables ***
${DEVICE_SESSION}    device_1
${DEVICE_NODE_ID}    1.1.1.1
${CLUSTER_NODE_ID}    2.2.2.2

*** Keywords ***
Setup SXP Cluster Session
    [Documentation]    Create sessions asociated with SXP cluster setup
    Setup SXP Session    ${DEVICE_SESSION}    ${TOOLS_SYSTEM_IP}
    Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    20    1    Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}    system=${TOOLS_SYSTEM_IP}    ip=${EMPTY}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Setup SXP Session    controller${i+1}    ${ODL_SYSTEM_${i+1}_IP}
    ClusterManagement_Setup
    ${controller_id}    Get Any Controller
    Add Node    ${CLUSTER_NODE_ID}    ip=0.0.0.0    session=controller${controller_id}
    Wait Until Keyword Succeeds    20    1    Check Cluster Node started    ${CLUSTER_NODE_ID}

Clean SXP Cluster Session
    [Documentation]    Clean sessions asociated with SXP cluster setup
    Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Rejoin_Member_From_List_Or_All    ${i+1}
    \    Flush_Iptables_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Wait Until Keyword Succeeds    10    1    Sync Status Should Be True    ${i}
    ${controller_index}    Get Any Controller
    Delete Node    ${CLUSTER_NODE_ID}    session=controller${controller_index}
    Clean SXP Session

Setup SXP Cluster
    [Arguments]    ${peer_mode}=listener
    [Documentation]    Setup and connect SXP cluster topology
    ${cluster_mode}    get opposing mode    ${peer_mode}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Connection    version4    ${peer_mode}    ${ODL_SYSTEM_${i+1}_IP}    64999    ${DEVICE_NODE_ID}
    \    ...    session=${DEVICE_SESSION}
    ${controller_id}    Get Any Controller
    Add Connection    version4    ${cluster_mode}    ${TOOLS_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Clean SXP Cluster
    [Documentation]    Disconnect SXP cluster topology
    Clean Connections    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Clean Bindings    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Rejoin_Member_From_List_Or_All    ${i+1}
    \    Flush_Iptables_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Wait Until Keyword Succeeds    10    1    Sync Status Should Be True    ${i}
    ${controller_index}    Get Any Controller
    Clean Connections    ${CLUSTER_NODE_ID}    session=controller${controller_index}
    Clean Bindings    ${CLUSTER_NODE_ID}    session=controller${controller_index}

Check Cluster Node started
    [Arguments]    ${node}    ${port}=64999    ${ip}=${EMPTY}
    [Documentation]    Verify that SxpNode has data writed to Operational datastore and Node is running on one of cluster nodes
    ${started}    Set variable    ${False}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${resp}    RequestsLibrary.Get Request    controller${i+1}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    ${rc}    Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    \    ...    prompt=${ODL_SYSTEM_PROMPT}
    \    ${started}    set variable if    '${rc}' == '0'    ${True}    ${started}
    should be true    ${started}

Check Device is Connected
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Checks if SXP device is connected to at least one cluster node
    ${is_connected}    Set variable    ${False}
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${is_connected}    Run Keyword If    ${follower}    Set Variable    ${True}
    \    ...    ELSE    Set Variable    ${is_connected}
    Should Be True    ${is_connected}

Get Active Controller
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Find cluster controller that is actively connected to SXP device
    ${controller}    Set variable    ${EMPTY}
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${found}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${controller}    Run Keyword If    ${found}    Set Variable    ${i+1}
    \    ...    ELSE    Set Variable    ${controller}
    [Return]    ${controller}

Get Inactive Controller
    [Arguments]    ${node}    ${version}=version4    ${mode}=listener    ${port}=64999    ${session}=session
    [Documentation]    Find cluster controller that is not actively connected to SXP device
    @{controllers}    Create List
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${found}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    Run Keyword If    not ${found}    Append To List    ${controllers}    ${i+1}
    Log    ${controllers}
    ${controller}    Evaluate    random.choice( ${controllers})    random
    [Return]    ${controller}

Get Any Controller
    [Documentation]    Get any cotroller from cluster range
    ${follower}    Evaluate    random.choice( range(1, ${NUM_ODL_SYSTEM} + 1))    random
    [Return]    ${follower}

Sync Status Should Be False
    [Arguments]    ${controller_index}
    [Documentation]    Verify that cluster node is not in sync with others
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    should not be true    ${status}

Sync Status Should Be True
    [Arguments]    ${controller_index}
    [Documentation]    Verify that cluster node is in sync with others
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    should be true    ${status}

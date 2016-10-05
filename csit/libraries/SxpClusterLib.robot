*** Settings ***
Documentation     Test suite TODO
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
Setup SXP Cluster
    [Arguments]    ${peer_mode}=listener
    [Documentation]    TODO
    ${cluster_mode}    get opposing mode    ${peer_mode}
    Setup SXP Session    ${DEVICE_SESSION}    ${TOOLS_SYSTEM_IP}
    Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    20    1    Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}    system=${TOOLS_SYSTEM_IP}    ip=${EMPTY}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Connection    version3    ${peer_mode}    ${ODL_SYSTEM_${i+1}_IP}    64999    ${DEVICE_NODE_ID}
    \    ...    session=${DEVICE_SESSION}
    \    Setup SXP Session    controller${i}    ${ODL_SYSTEM_${i+1}_IP}
    ClusterManagement_Setup
    ${controller_id}    Get Any Controller
    Add Node    ${CLUSTER_NODE_ID}    ip=0.0.0.0    session=controller${controller_id}
    Wait Until Keyword Succeeds    20    1    Check Cluster Node started    ${CLUSTER_NODE_ID}
    Add Connection    version3    ${cluster_mode}    ${TOOLS_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Clean SXP Cluster
    [Documentation]    TODO
    Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Rejoin_Member_From_List_Or_All    ${i+1}
    \    Delete Node    ${CLUSTER_NODE_ID}    session=controller${i}
    RequestsLibrary.Delete_All_Sessions

Check Cluster Node started
    [Arguments]    ${node}    ${port}=64999    ${ip}=${EMPTY}
    [Documentation]    Verify that SxpNode has data writed to Operational datastore
    ${started}    Set variable    ${False}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${resp}    RequestsLibrary.Get Request    controller${i}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    ${rc}    Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    \    ...    prompt=${ODL_SYSTEM_PROMPT}
    \    ${started}    set variable if    '${rc}' == '0'    ${True}    ${started}
    should be true    ${started}

Check Device is Connected
    [Arguments]    ${node}    ${version}=version3    ${port}=64999    ${session}=session
    [Documentation]    TODO
    ${is_connected}    Set variable    ${False}
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${is_connected}    Run Keyword If    ${follower}    Set Variable    ${True}
    \    ...    ELSE    Set Variable    ${is_connected}
    Should Be True    ${is_connected}

Get Active Controller
    [Arguments]    ${node}    ${version}=version3    ${port}=64999    ${session}=session
    [Documentation]    TODO
    ${controller}    Set variable    ${EMPTY}
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${found}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${controller}    Run Keyword If    ${found}    Set Variable    ${i+1}
    \    ...    ELSE    Set Variable    ${controller}
    log to console    \nACTIVE ${controller}\n
    [Return]    ${controller}

Get Inactive Controller
    [Arguments]    ${node}    ${version}=version3    ${mode}=listener    ${port}=64999    ${session}=session
    [Documentation]    TODO
    @{controllers}    Create List
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${found}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    Run Keyword If    not ${found}    Append To List    ${controllers}    ${i+1}
    Log    ${controllers}
    ${controller}    Evaluate    random.choice( ${controllers})    random
    log to console    \nINACTIVE ${controller}\n
    [Return]    ${controller}

Get Any Controller
    [Documentation]    TODO
    ${follower}    Evaluate    random.choice( range(1, ${NUM_ODL_SYSTEM}))    random
    log to console    \nANY ${follower}\n
    [Return]    ${follower}

Sync Status Should Be False
    [Arguments]    ${controller_index}
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    should not be true    ${status}

Sync Status Should Be True
    [Arguments]    ${controller_index}
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    should be true    ${status}

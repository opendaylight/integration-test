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
    Setup SXP Session    ${DEVICE_SESSION}
    Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    #Wait Until Keyword Succeeds    20    1    Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Sleep    5s
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Connection    version3    ${peer_mode}    ${ODL_SYSTEM_${i+1}_IP}    64999    ${DEVICE_NODE_ID}
    \    ...    session=${DEVICE_SESSION}
    \    Setup SXP Session    controller${i}    ${ODL_SYSTEM_${i+1}_IP}
    ClusterManagement_Setup
    ${controller_id}    Get Any Controller
    Add Node    ${CLUSTER_NODE_ID}    ip=0.0.0.0    session=controller${controller_id}
    Add Connection    version3    ${cluster_mode}    ${ODL_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Clean SXP Cluster
    [Documentation]    TODO
    Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Rejoin_Member_From_List_Or_All    ${i+1}
    ${controller_id}    Get Any Controller
    Delete Node    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    RequestsLibrary.Delete_All_Sessions

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
    Log     ${controllers}
    ${controller}    Evaluate    random.choice( ${controllers})    random
    [Return]    ${controller}

Get Any Controller
    [Documentation]    TODO
    ${follower}    Evaluate    random.choice( range(1, ${NUM_ODL_SYSTEM}))    random
    [Return]    ${follower}

Sync Status Should Be False
    [Arguments]    ${controller_index}
    [Documentation]
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    should not be true    ${status}

Sync Status Should Be True
    [Arguments]    ${controller_index}
    [Documentation]
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    should be true    ${status}
*** Settings ***
Documentation     Test suite TODO
Suite Setup       Setup SXP Cluster
Suite Teardown    Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SetupUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${SXP_VERSION}    version4
${DEVICE_SESSION}    device_1
${DEVICE_NODE_ID}    1.1.1.1
${CLUSTER_NODE_ID}    2.2.2.2
${SAMPLES}        1
#robot -v ODL_STREAM:boron -v ODL_SYSTEM_IP:192.168.50.14 -v ODL_SYSTEM_1_IP:192.168.50.11 -v ODL_SYSTEM_2_IP:192.168.50.12 -v ODL_SYSTEM_3_IP:192.168.50.13 -v NUM_ODL_SYSTEM:3 -v ODL_SYSTEM_USER:vagrant -v ODL_SYSTEM_PASSWORD:vagrant ./010_Connection_switchover.robot

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    TODO
    pass execution    SKIP
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of SXP noservice follower Test
    [Documentation]    TODO
    pass execution    SKIP
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of random follower Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Any Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Setup SXP Cluster
    [Documentation]    TODO
    Setup SXP Session    ${DEVICE_SESSION}
    Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    20    1    Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Connection    ${SXP_VERSION}    listener    ${ODL_SYSTEM_${i+1}_IP}    64999    ${DEVICE_NODE_ID}
    \    ...    session=${DEVICE_SESSION}
    Create Controller Sessions
    ClusterManagement.ClusterManagement_Setup
    ${controller_id}    Get Any Controller
    Add Node    ${CLUSTER_NODE_ID}    ip=0.0.0.0    session=controller${controller_id}
    Add Connection    ${SXP_VERSION}    speaker    ${ODL_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Clean SXP Cluster
    [Documentation]    TODO
    Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Rejoin_Member_From_List_Or_All    ${i+1}
    ${controller_id}    Get Any Controller
    Delete Node    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    RequestsLibrary.Delete_All_Sessions

Isolate SXP Controller
    [Arguments]    ${controller_index}
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Controller Sync Status Should Be False    ${ODL_SYSTEM_${controller_index}_IP}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Rejoin_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Controller Sync Status Should Be True    ${ODL_SYSTEM_${controller_index}_IP}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Check Device is Connected
    [Arguments]    ${node}    ${version}=${SXP_VERSION}    ${port}=64999    ${session}=session
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
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${session}=session
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
    [Arguments]    ${node}    ${version}=version4    ${mode}=listener    ${port}=64999    ${session}=session
    [Documentation]    TODO
    @{controllers}    Create List
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${found}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    Run Keyword If    not ${found}    Append To List    ${controllers}    ${i+1}
    Log     ${controllers}
    ${controller}    Evaluate    __import__('random').choice( ${controllers})
    [Return]    ${controller}

Get Any Controller
    [Documentation]    TODO
    ${follower}    Evaluate    __import__('random').choice( range(1, ${NUM_ODL_SYSTEM}))
    [Return]    ${follower}

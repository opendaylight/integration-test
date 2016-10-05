*** Settings ***
Documentation     Test suite TODO
Suite Setup       Setup SXP Cluster
Suite Teardown    Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        1

*** Test Cases ***
Isolation of RCP service Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of RPC noservice Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of random follower Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Any Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Isolate SXP Controller
    [Arguments]    ${controller_index}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM+1}
    \    Add Binding    ${i}0    ${i}0.${i}0.${i}0.${i}0/32    node=${CLUSTER_NODE_ID}    session=controller${i}
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be False    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    60    1    Check Bindings Exist
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM+1}
    \    Delete Binding    ${i}0    ${i}0.${i}0.${i}0.${i}0/32    node=${CLUSTER_NODE_ID}    session=controller${i}
    Rejoin_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be True    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    60    1    Check Bindings Does Not Exist

Check Bindings Exist
    [Arguments]
    [Documentation]    TODO
    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${resp}    Get Bindings    node=${CLUSTER_NODE_ID}    session=controller${controller_index}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM+1}
    \    Should Contain Binding    ${resp}    ${i}0    ${i}0.${i}0.${i}0.${i}0/32

Check Bindings Does Not Exist
    [Arguments]
    [Documentation]    TODO
    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${resp}    Get Bindings    node=${CLUSTER_NODE_ID}    session=controller${controller_index}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM+1}
    \    Should Not Contain Binding    ${resp}    ${i}0    ${i}0.${i}0.${i}0.${i}0/32


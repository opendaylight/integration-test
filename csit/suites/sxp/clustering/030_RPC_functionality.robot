*** Settings ***
Documentation     Test suite to verify RPC funcionality on cluster
Suite Setup       Setup SXP Cluster Session
Suite Teardown    Clean SXP Cluster Session
Test Setup        Setup SXP Cluster
Test Teardown     Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        1

*** Test Cases ***
Isolation of RCP service Test
    [Documentation]    Test SXP RPC functionality only if Controller with SCS is isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of RPC noservice Test
    [Documentation]    Test SXP RPC functionality only if Controller without SCS are isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of random follower Test
    [Documentation]    Test SXP RPC functionality if any Controller is isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Any Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that RPC changes were performed afterwards reverts isolation
    ${active_controller}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Binding    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32    node=${CLUSTER_NODE_ID}    session=controller${active_controller}
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be False    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    60    1    Check Bindings Exist
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Delete Binding    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32    node=${CLUSTER_NODE_ID}    session=controller${active_controller}
    Rejoin_Member_From_List_Or_All    ${controller_index}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be True    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    60    1    Check Bindings Does Not Exist

Check Bindings Exist
    [Documentation]    Check that bindings exists in Cluster datastore
    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${resp}    Get Bindings    node=${CLUSTER_NODE_ID}    session=controller${controller_index}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Should Contain Binding    ${resp}    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32

Check Bindings Does Not Exist
    [Documentation]    Check that bindings does not exist in Cluster datastore
    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${resp}    Get Bindings    node=${CLUSTER_NODE_ID}    session=controller${controller_index}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Should Not Contain Binding    ${resp}    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32

*** Settings ***
Documentation     Test suite to test cluster binding propagation
Suite Setup       Setup SXP Cluster Session
Suite Teardown    Clean SXP Cluster Session
Test Teardown     Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        1

*** Test Cases ***
Isolation of SXP service follower Test Listener Part
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    Setup Custom SXP Cluster    listener    ${CLUSTER_NODE_ID}    controller1
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}

Isolation of SXP service follower Test Speaker Part
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    Setup Custom SXP Cluster    speaker
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}    ${CLUSTER_NODE_ID}

Isolation of SXP noservice follower Test Listener Part
    [Documentation]    Test SXP binding propagation only if Controller without SCS are isolated
    Setup Custom SXP Cluster    listener    ${CLUSTER_NODE_ID}    controller1
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller
    \    Isolate SXP Controller    ${controller_index}    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}

Isolation of SXP noservice follower Test Speaker Part
    [Documentation]    Test SXP binding propagation only if Controller without SCS are isolated
    Setup Custom SXP Cluster    speaker
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller
    \    Isolate SXP Controller    ${controller_index}    ${CLUSTER_NODE_ID}

*** Keywords ***
Setup Custom SXP Cluster
    [Arguments]    ${mode}    ${node}=${DEVICE_NODE_ID}    ${session}=${DEVICE_SESSION}
    [Documentation]    Setup custom SXP cluster topology
    Setup SXP Cluster    ${mode}
    : FOR    ${i}    IN RANGE    1    25
    \    Add Binding    ${i}0    ${i}.${i}.${i}.${i}/32    node=${node}    session=${session}

Check Bindings
    [Arguments]    ${node}    ${session}
    [Documentation]    Checks that bindings were propagated to Peer
    ${resp}    Get Bindings    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    1    25
    \    Should Contain Binding    ${resp}    ${i}0    ${i}.${i}.${i}.${i}/32

Isolate SXP Controller
    [Arguments]    ${controller_index}    ${node}    ${session}=${EMPTY}
    [Documentation]    Isolate one of cluster nodes and perform check that bindings were propagated afterwards reverts isolation
    ${find_session}    Set Variable If    '${session}' == ''    ${True}    ${False}
    ${session}    Set Variable If    ${find_session}    controller${controller_index}    ${session}
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be False    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${active_controller}    Get Active Controller
    ${session}    Set Variable If    ${find_session}    controller${active_controller}    ${session}
    Wait Until Keyword Succeeds    120    1    Check Bindings    ${node}    ${session}
    Rejoin_Member_From_List_Or_All    ${controller_index}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be True    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    120    1    Check Bindings    ${node}    ${session}

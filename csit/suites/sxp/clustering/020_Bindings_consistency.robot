*** Settings ***
Documentation     Test suite to test cluster binding propagation
Suite Setup       SxpClusterLib.Setup SXP Cluster Session With Device
Suite Teardown    SxpClusterLib.Clean SXP Cluster Session
Test Teardown     SxpClusterLib.Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Isolation of SXP service follower Test Listener Part
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    SxpClusterLib.Check Shards Status
    Setup Custom SXP Cluster    listener    ${INADDR_ANY}    ${CONTROLLER_SESSION}
    ${controller_index} =    SxpClusterLib.Get Owner Controller
    Isolate SXP Controller    ${controller_index}    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}

Isolation of SXP service follower Test Speaker Part
    [Documentation]    Test SXP binding propagation only if Controller with SCS is isolated
    SxpClusterLib.Check Shards Status
    Setup Custom SXP Cluster    speaker
    ${controller_index} =    SxpClusterLib.Get Owner Controller
    Isolate SXP Controller    ${controller_index}    ${INADDR_ANY}

Isolation of SXP noservice follower Test Listener Part
    [Documentation]    Test SXP binding propagation only if Controller without SCS are isolated
    SxpClusterLib.Check Shards Status
    Setup Custom SXP Cluster    listener    ${INADDR_ANY}    ${CONTROLLER_SESSION}
    ${controller_index} =    SxpClusterLib.Get Not Owner Controller
    Isolate SXP Controller    ${controller_index}    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}

Isolation of SXP noservice follower Test Speaker Part
    [Documentation]    Test SXP binding propagation only if Controller without SCS are isolated
    SxpClusterLib.Check Shards Status
    Setup Custom SXP Cluster    speaker
    ${controller_index} =    SxpClusterLib.Get Not Owner Controller
    Isolate SXP Controller    ${controller_index}    ${INADDR_ANY}

*** Keywords ***
Setup Custom SXP Cluster
    [Arguments]    ${mode}    ${node}=${DEVICE_NODE_ID}    ${session}=${DEVICE_SESSION}
    [Documentation]    Setup custom SXP cluster topology
    SxpClusterLib.Setup SXP Cluster    ${mode}
    : FOR    ${i}    IN RANGE    1    25
    \    SxpLib.Add Bindings    ${i}0    ${i}.${i}.${i}.${i}/32    node=${node}    session=${session}

Isolate SXP Controller
    [Arguments]    ${controller_index}    ${node}    ${session}=ClusterManagement__session_${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that bindings were propagated afterwards reverts isolation
    @{running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    60    1    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${running_member} =    Collections.Get From List    ${running_members}    0
    ${owner_controller} =    SxpClusterLib.Get Owner Controller    ${running_member}
    BuiltIn.Wait Until Keyword Succeeds    30    1    Check Bindings    ${node}    ${session}
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_True    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    60    1    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    30    1    Check Bindings    ${node}    ${session}

Check Bindings
    [Arguments]    ${node}    ${session}
    [Documentation]    Checks that bindings were propagated to Peer
    ${resp} =    SxpLib.Get Bindings    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    1    25
    \    SxpLib.Should Contain Binding    ${resp}    ${i}0    ${i}.${i}.${i}.${i}/32

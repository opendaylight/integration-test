*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       Setup SXP Cluster Session
Suite Teardown    Clean SXP Cluster Session
Test Setup        Setup SXP Cluster
Test Teardown     Clean SXP Cluster
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    Test SXP connection switchover only if Controller with SCS is isolated
    SxpClusterLib.Check Shards Status
    ${controller_index} =    SxpClusterLib.Get Active Controller
    Isolate SXP Controller    ${controller_index}

Isolation of SXP noservice follower Test
    [Documentation]    Test SXP connection switchover only if Controller without SCS are isolated
    SxpClusterLib.Check Shards Status
    ${controller_index} =    SxpClusterLib.Get Inactive Controller
    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected afterwards reverts isolation
    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    60    1    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_True    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    60    1    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

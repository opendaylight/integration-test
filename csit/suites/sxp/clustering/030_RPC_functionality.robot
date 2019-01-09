*** Settings ***
Documentation     Test suite to verify RPC funcionality on cluster
Suite Setup       SxpClusterLib.Setup SXP Cluster Session With Device
Suite Teardown    SxpClusterLib.Clean SXP Cluster Session
Test Setup        SxpClusterLib.Setup SXP Cluster
Test Teardown     SxpClusterLib.Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Isolation of RCP service Test
    [Documentation]    Test SXP RPC functionality only if Controller with SCS is isolated
    SxpClusterLib.Check Shards Status
    ${controller_index} =    SxpClusterLib.Get Owner Controller
    Isolate SXP Controller    ${controller_index}

Isolation of RPC noservice Test
    [Documentation]    Test SXP RPC functionality only if Controller without SCS are isolated
    SxpClusterLib.Check Shards Status
    ${controller_index} =    SxpClusterLib.Get Not Owner Controller
    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that RPC changes were performed afterwards reverts isolation
    ${owner_controller} =    SxpClusterLib.Get Owner Controller
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    SxpLib.Add Bindings    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32    node=${INADDR_ANY}    session=ClusterManagement__session_${owner_controller}
    @{running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Sleep    1m    Allow cluster to get healthy again after isolation/reisolation
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    ${running_member} =    Collections.Get From List    ${running_members}    0
    ${owner_controller} =    SxpClusterLib.Get Owner Controller    ${running_member}
    BuiltIn.Wait Until Keyword Succeeds    30    1    Check Bindings Exist    ${owner_controller}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    SxpLib.Delete Bindings    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32    node=${INADDR_ANY}    session=ClusterManagement__session_${owner_controller}
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Sleep    1m    Allow cluster to get healthy again after isolation/reisolation
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Check_Cluster_Is_In_Sync
    BuiltIn.Wait Until Keyword Succeeds    30    1    Check Bindings Does Not Exist    ${owner_controller}

Check Bindings Exist
    [Arguments]    ${owner_controller}
    [Documentation]    Check that bindings exists in Cluster datastore
    ${resp} =    SxpLib.Get Bindings    node=${INADDR_ANY}    session=ClusterManagement__session_${owner_controller}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    SxpLib.Should Contain Binding    ${resp}    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32

Check Bindings Does Not Exist
    [Arguments]    ${owner_controller}
    [Documentation]    Check that bindings does not exist in Cluster datastore
    ${resp} =    SxpLib.Get Bindings    node=${INADDR_ANY}    session=ClusterManagement__session_${owner_controller}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    SxpLib.Should Not Contain Binding    ${resp}    ${i+1}0    ${i+1}0.${i+1}0.${i+1}0.${i+1}0/32

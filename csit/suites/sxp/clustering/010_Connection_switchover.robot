*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       SxpClusterLib.Setup SXP Cluster Session With Device
Suite Teardown    SxpClusterLib.Clean SXP Cluster Session
Test Setup        SxpClusterLib.Setup SXP Cluster
Test Teardown     SxpClusterLib.Clean SXP Cluster
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    Test SXP connection switchover only if Controller with SCS is isolated
    SxpClusterLib.Check Shards Status
    ${controller_index} =    SxpClusterLib.Get Owner Controller
    Isolate SXP Controller    ${controller_index}

Isolation of SXP noservice follower Test
    [Documentation]    Test SXP connection switchover only if Controller without SCS are isolated
    SxpClusterLib.Check Shards Status
    ${controller_index} =    SxpClusterLib.Get Not Owner Controller
    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected afterwards reverts isolation
    ${running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    60    1    ClusterManagement.Verify_Members_Are_Ready    member_index_list=${running_members}    verify_cluster_sync=True    verify_restconf=True
    ...    verify_system_status=False    service_list=${EMPTY_LIST}
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    60    1    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait_Until_Keyword_Succeeds    60    1    ClusterManagement.Verify_Members_Are_Ready    member_index_list=${EMPTY}    verify_cluster_sync=True    verify_restconf=True
    ...    verify_system_status=False    service_list=${EMPTY_LIST}
    BuiltIn.Wait Until Keyword Succeeds    60    1    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       Setup SXP Cluster Session
Suite Teardown    Clean SXP Cluster Session
Test Setup        Setup SXP Cluster
Test Teardown     Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        1

*** Test Cases ***
Check Shards Status
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Check Status for all shards in SXP application.
    ClusterManagement.Check_Cluster_Is_In_Sync
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational    member_index_list=${controller_index_list}
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config    member_index_list=${controller_index_list}

Isolation of SXP service follower Test
    [Documentation]    Test SXP connection switchover only if Controller with SCS is isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}

Isolation of SXP noservice follower Test
    [Documentation]    Test SXP connection switchover only if Controller without SCS are isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected afterwards reverts isolation
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

*** Settings ***
Documentation     Suite for performing member isolation and rejoin, we do with entity-ownership leader.
Suite Setup       Setup
Suite Teardown    Teardown
Default Tags      clustering    carpeople    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
@{SHARD_OPER_LIST}    car    people    car-people    inventory    topology    default    toaster
...               entity-ownership
@{SHARD_CONF_LIST}    car    people    car-people    inventory    topology    default    toaster

*** Test Cases ***
Check All Shards Before Isolate
    [Documentation]    Check all shards in controller.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config

Isolate Entity Leader
    [Documentation]    Isolate the entity-ownership Leader to cause a new leader to get elected.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${entity-ownership_leader_index}

Check All Shards After Isolate
    [Documentation]    Check all shards in controller.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational    member_index_list=${entity-ownership_follower_indices}
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config    member_index_list=${entity-ownership_follower_indices}

Rejoin Entity Leader
    [Documentation]    Rejoin the entity-ownership Leader.
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${entity-ownership_leader_index}

Check All Shards After Rejoin
    [Documentation]    Check all shards in controller.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize car shard leader and followers.
    ClusterManagement.ClusterManagement_Setup
    CarPeople.Set_Variables_For_Shard    shard_name=entity-ownership    shard_type=operational

Teardown
    [Documentation]    Clear IPTables in all nodes.
    ClusterManagement.Flush_Iptables_From_List_Or_All

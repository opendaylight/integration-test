*** Settings ***
Documentation     This test waits until cluster appears to be ready.
...               Intended use is at a start of testplan so that suites can assume cluster works.
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      3-node-cluster    critical
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    60s
${TIMEOUT_BUG_4220}    20s

*** Test Cases ***
Wait_For_Sync
    [Documentation]    Repeatedly check for cluster sync status, pass if sync within timeout.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${CLUSTER_BOOTUP_SYNC_TIMEOUT}    10s    Check_Sync_And_Shards

Check_Bug_4220
    [Documentation]    Issue (invalid) RPC requests until 501 goes away (or timeout expires).
    ...    FIXME: Use proper reporting Keyword in Teardown.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${TIMEOUT_BUG_4220}    5s    Check_Rpc_Readiness

*** Keywords ***
Check_Sync_And_Shards
    ClusterManagement.Check_Cluster_Is_In_Sync
    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=car    shard_type=config
    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=people    shard_type=config
    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=car-people    shard_type=config

Check_Rpc_Readiness
    [Documentation]    Issue invalid RPC requests and assert appropriate http status code
    # So far only buy-car is checked, but other RPCs such as add-car may be added later.
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    TemplatedRequests.Post_As_Json_To_Uri    uri=restconf/operations/car-purchase:buy-car    data={"input":{}}    session=${session}
    \    # TODO: Create template directory for this?
    \    BuiltIn.Should_Not_Contain    ${message}    '50

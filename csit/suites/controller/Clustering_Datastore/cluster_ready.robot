*** Settings ***
Documentation     This test waits until cluster appears to be ready.
...               Intended use is at a start of testplan so that suites can assume cluster works.
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      3-node-cluster    critical
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    60s

*** Test Cases ***
Wait_For_Sync
    [Documentation]    Repeatedly check for cluster sync status, pass if sync within timeout.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${CLUSTER_BOOTUP_SYNC_TIMEOUT}    10s    Check_Sync_And_Shards

*** Keywords ***
Check_Sync_And_Shards
    ClusterManagement.Check_Cluster_Is_In_Sync
    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=car    shard_type=config
    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=people    shard_type=config
    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=car-people    shard_type=config

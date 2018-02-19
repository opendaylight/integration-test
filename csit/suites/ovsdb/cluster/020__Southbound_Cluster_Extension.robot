*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster - Candidate failover and recover
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    Delete All Sessions
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SetupUtils.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status

Start OVS Multiple Connections
    [Documentation]    Connect OVS to all cluster instances.
    ${ovsdb_uuid}    Ovsdb.Add Multiple Managers to OVS
    Set Suite Variable    ${ovsdb_uuid}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidate_list}    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate}=    Get From List    ${original_candidate_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Create Bridge Manually and Verify Before Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify

Add Port Manually and Verify Before Fail
    [Documentation]    Add port with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Port To The Manual Bridge And Verify

Delete the Bridge Manually and Verify Before Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify

Create Bridge In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge And Verify    ${original_owner}

Create Port In Owner and Verify Before Fail
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Port And Verify    ${original_owner}

Modify the destination IP of Port In Owner Before Fail
    [Documentation]    Modify the dst ip of existing port in Owner.
    ClusterOvsdb.Modify the destination IP of Sample Port    ${original_owner}

Verify Port Is Modified Before Fail
    [Documentation]    Verify port is modified in all instances.
    ClusterOvsdb.Verify Sample Port Is Modified

Delete Port In Owner Before Fail
    [Documentation]    Delete port in Owner and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Port And Verify    ${original_owner}

Delete Bridge In Owner And Verify Before Fail
    [Documentation]    Delete bridge in Owner and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge And Verify    ${original_owner}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list}    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate}=    Get From List    ${new_candidate_list}    0
    Set Suite Variable    ${new_owner}
    Set Suite Variable    ${new_candidate}

Create Bridge Manually and Verify After Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    controller_index_list=${new_cluster_list}

Add Port Manually and Verify After Fail
    [Documentation]    Add port with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Port To The Manual Bridge And Verify    controller_index_list=${new_cluster_list}

Delete the Bridge Manually and Verify After Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    controller_index_list=${new_cluster_list}

Create Bridge In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge And Verify    ${new_owner}    ${new_cluster_list}

Create Port In Owner and Verify After Fail
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Port And Verify    ${new_owner}    ${new_cluster_list}

Modify the destination IP of Port In Owner After Fail
    [Documentation]    Modify the dst ip of existing port in Owner.
    ClusterOvsdb.Modify the destination IP of Sample Port    ${new_owner}    ${new_cluster_list}

Verify Port Is Modified After Fail
    [Documentation]    Verify port is modified in all instances.
    ClusterOvsdb.Verify Sample Port Is Modified    ${new_cluster_list}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list}    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    Set Suite Variable    ${new_owner}

Create Bridge Manually and Verify After Recover
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify

Add Port Manually and Verify After Recover
    [Documentation]    Add port with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Port To The Manual Bridge And Verify

Delete the Bridge Manually and Verify After Recover
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify

Verify Modified Port After Recover
    [Documentation]    Verify modified port exists in all instances.
    ClusterOvsdb.Verify Sample Port Is Modified

Delete Port In New Owner After Recover
    [Documentation]    Delete port in Owner and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Port And Verify    ${new_owner}

Delete Bridge In New Owner And Verify After Recover
    [Documentation]    Delete bridge in Owner and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge And Verify    ${new_owner}

Create Bridge In Old Candidate and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge And Verify    ${original_candidate}

Create Port In Old Owner and Verify After Recover
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Port And Verify    ${original_candidate}

Modify the destination IP of Port In Old Owner After Recover
    [Documentation]    Modify the dst ip of existing port in Owner.
    ClusterOvsdb.Modify the destination IP of Sample Port    ${original_candidate}

Verify Port Is Modified After Recover
    [Documentation]    Verify port is modified in all instances.
    ClusterOvsdb.Verify Sample Port Is Modified

Delete Port In Old Owner After Recover
    [Documentation]    Delete port in Owner and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Port And Verify    ${original_candidate}

Delete Bridge In Old Owner And Verify After Recover
    [Documentation]    Delete bridge in Owner and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge And Verify    ${original_candidate}

Cleans Up Test Environment For Next Suite
    [Documentation]    Cleans up test environment, close existing sessions in teardown.
    ClusterOvsdb.Configure Exit OVSDB Connection

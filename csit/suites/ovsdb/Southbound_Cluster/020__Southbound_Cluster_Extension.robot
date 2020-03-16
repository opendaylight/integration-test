*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster - Candidate failover and recover
Suite Setup       Suite Setup
Suite Teardown    Delete All Sessions
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           Collections
Library           RequestsLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Test Cases ***
Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status

Start OVS Multiple Connections
    [Documentation]    Connect OVS to all cluster instances.
    ${ovsdb_uuid} =    Ovsdb.Add Multiple Managers to OVS
    BuiltIn.Set Suite Variable    ${ovsdb_uuid}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

heck Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat start
    ${original_owner}    ${original_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    ${original_candidate} =    Collections.Get From List    ${original_candidate_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_candidate}

Kill Candidate Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    ${original_candidate}
    BuiltIn.Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    ${original_owner}    ${new_cluster_list}
    ${new_candidate} =    Collections.Get From List    ${new_candidate_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_candidate}

Start Old Candidate Instance
    [Documentation]    Start Owner Instance and verify it is active
    ClusterManagement.Start Single Member    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    [Tags]    repeat end
    ${new_owner}    ${new_candidate_list} =    ClusterOvsdb.Get Ovsdb Entity Owner Status For One Device    ovsdb://uuid/${ovsdb_uuid}    1
    BuiltIn.Set Suite Variable    ${new_owner}

*** Keywords ***
Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement Setup

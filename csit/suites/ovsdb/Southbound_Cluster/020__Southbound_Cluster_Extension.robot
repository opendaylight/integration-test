*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster Extension
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${BRIDGE}         br01

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Create Bridge Via Controller In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge In Candidate    ${original_cluster_list}    ${original_owner}    BeforeCandidateFail

Create Port Via Controller In Owner and Verify Before Fail
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Vxlan in Candidate    ${original_cluster_list}    ${original_owner}    BeforeCandidateFail

Kill Non Owner Instance
    [Documentation]    Kill Non Owner Instance and verify it is dead
    Kill Multiple Controllers    ${original_candidate}
    ${new_cluster_list}    Create Controller Index List
    Remove Values From List    ${new_cluster_list}    ${original_candidate}
    Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${new_cluster_list}
    Run Keyword And Continue On Failure    List Should Not Contain Value    ${new_candidates_list}    ${original_candidate}    Original candidate ${original_candidate} still in candidate list.
    Remove Values From List    ${new_candidates_list}    ${original_candidate}
    ${new_candidate}=    Get From List    ${new_candidates_list}    0
    Set Suite Variable    ${new_owner}
    Set Suite Variable    ${new_candidate}

Create Bridge Via Controller In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge In Candidate    ${new_cluster_list}    ${new_owner}    AfterCandidateFail

Start Non Old Owner Instance
    [Documentation]    Start Non Owner Instance and verify it is active
    Start Multiple Controllers    300s    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status After Cluster Event    ${original_cluster_list}

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and verify owner is not changed.
    ${new_owner}    ${new_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    Set Suite Variable    ${new_owner}

Create Bridge Via Controller In Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge In Candidate    ${original_cluster_list}    ${new_owner}

Verify Bridge in Restarted Node Which Is Killed Earlier
    [Documentation]    Verify Bridge in Restarted node, which is created when the node is down.
    Verify Bridge in Restarted Node    ${original_cluster_list}    AfterCandidateRecover

Create Port Via Controller In Owner and Verify After Recover
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Vxlan in Candidate    ${original_cluster_list}    ${new_owner}

Verify Port in Restarted Node Which Is Killed Earlier
    [Documentation]    Verify Port in Restarted node, which is created when the node is down.
    Verify Port in Restarted Node    ${original_cluster_list}    AfterCandidateRecover

Delete the Port After Recover
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port In Candidate    ${original_cluster_list}    ${new_owner}

Delete Bridge Via Rest Call And Verify In Owner After Recover
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge In Candidate    ${original_cluster_list}    ${new_owner}

Cleans Up Test Environment For Next Suite
    [Documentation]    Cleans up test environment, close existing sessions in teardown. This step needs to be excluded
    ...    until the keyword "Get Cluster Entity Owner For Ovsdb" is fixed to search using ovs uuid as argument.
    [Tags]    exclude
    Configure Exit OVSDB Connection    ${original_cluster_list}    ${new_owner}

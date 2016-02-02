*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
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
${original_candidate}    2

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Kill Two Node Instances
    [Documentation]    Kill Owner Instance and verify it is dead
    Kill Multiple Controllers    ${original_owner}    ${original_candidate}
    ${new_cluster_list}    Create Controller Index List
    Remove Values From List    ${new_cluster_list}    ${original_owner}    ${original_candidate}
    Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${new_cluster_list}
    Run Keyword And Continue On Failure    List Should Not Contain Value    ${new_candidates_list}    ${original_owner}    Original owner ${original_owner} still in candidate list.
    Remove Values From List    ${new_candidates_list}    ${original_owner}
    ${new_candidate}=    Get From List    ${new_candidates_list}    0
    Set Suite Variable    ${new_owner}
    Set Suite Variable    ${new_candidate}

Create Bridge Manually In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${new_cluster_list}    ${new_owner}

Add Port Manually In Owner and Verify After Fail
    [Documentation]    Add Port in Owner and verify it gets applied from all instances.
    Add Port To The Manual Bridge And Verify    ${new_cluster_list}    ${new_owner}

Create Bridge Via Controller In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${new_cluster_list}    ${new_owner}    AfterFail

Create Port Via Controller In Owner and Verify After Fail
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Via Controller    ${new_cluster_list}    ${new_owner}    AfterFail

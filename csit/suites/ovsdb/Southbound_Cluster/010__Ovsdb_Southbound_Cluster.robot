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
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDBPORT}
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

Create Bridge In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${original_owner}

Kill Owner Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    Kill Multiple Controllers    ${original_owner}
    ${new_cluster_list}    Create Controller Index List
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${new_cluster_list}
    ${new_candidate}=    Get From List    ${new_candidates_list}    0
    Set Suite Variable    ${new_owner}
    Set Suite Variable    ${new_candidate}

Create Bridge In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${new_cluster_list}    ${new_owner}

Modify Network and Verify After Fail
    [Documentation]    Take a link down and verify port status in all instances.
    Take Ovsdb Device Link Down and Verify    ${new_cluster_list}

Restore Network and Verify After Fail
    [Documentation]    Take the link up and verify port status in all instances.
    Take Ovsdb Device Link Up and Verify    ${new_cluster_list}

Start Old Owner Instance
    [Documentation]    Start Owner Instance and verify it is active
    Start Multiple Controllers    300s    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${original_cluster_list}

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    Set Suite Variable    ${new_owner}

Check Network Operational Information After Recover
    [Documentation]    Check device is in operational inventory and topology in all cluster instances.
    Check Ovsdb Network Operational Information For One Device    ${original_cluster_list}

Create Bridge In Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${new_owner}

Create Bridge In Old Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${original_owner}

Up Owner Instance
    [Documentation]    Down Owner Instance and verify it is dead
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Kill Multiple Controllers    ${new_cluster_list}
    ${new_cluster_list}    Create Controller Index List
    Set Suite Variable    ${new_cluster_list}
    Take Ovsdb Device Link Up and Verify    ${original_owner}
    Take Ovsdb Device Link Down and Verify    ${new_cluster_list}

Create Bridge In Up Owner and Verify After Recover
    [Documentation]    Create Bridge in up Owner and verify it gets applied from all down instances.
    Create Bridge And Verify    ${new_cluster_list}    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${new_cluster_list}

Up Owner Instance
    [Documentation]    Down Owner Instance and verify it is dead
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Kill Multiple Controllers    ${new_cluster_list}
    ${new_cluster_list}    Create Controller Index List
    Set Suite Variable    ${new_cluster_list}
    Take Ovsdb Device Link Down and Verify    ${original_owner}
    Take Ovsdb Device Link Up and Verify    ${new_cluster_list}

Create Bridge In Up Owner and Verify After Recover
    [Documentation]    Create Bridge in up Owner and verify it gets applied from all down instances.
    Create Bridge And Verify    ${new_cluster_list}    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${new_cluster_list}

Check the fistnode Up and Scond and Third Restart Instance
    [Documentation]    Down the 3 node and check the remaing status.
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Kill Multiple Controllers    ${new_cluster_list}
    ${new_cluster_list}    Create Controller Index List
    Set Suite Variable    ${new_cluster_list}
    Take Ovsdb Device Link Up and Verify     ${original_owner}
    Take Ovsdb Device Link  Down and Verify  ${new_cluster_list}
    Take Ovsdb Device Link Up and Verify     ${original_owner}

Create Bridge In Up Owner and Verify After Recover
    [Documentation]    Create Bridge in up Owner and verify it gets applied from all down instances.
    Create Bridge And Verify    ${new_cluster_list}    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${new_cluster_list}

Check the fistnode Down and Scond and Third Restart  Instance
    [Documentation]    Down the 3 node and check the remaing status.
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Kill Multiple Controllers    ${new_cluster_list}
    ${new_cluster_list}    Create Controller Index List
    Set Suite Variable    ${new_cluster_list}
    Take Ovsdb Device Link Down and Verify     ${original_owner}
    Take Ovsdb Device Link  Up and Verify  ${new_cluster_list}
    Take Ovsdb Device Link Down and Verify     ${original_owner}

Create Bridge In Up Owner and Verify After Recover
    [Documentation]    Create Bridge in up Owner and verify it gets applied from all down instances.
    Create Bridge And Verify    ${new_cluster_list}    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${new_cluster_list}

To check the 3 nodes Restart Instance
    [Documentation]    Tovirify the status about all nodes restart.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Take Ovsdb Device Link Down and Verify     ${original_candidate}
    Take Ovsdb Device Link Up and Verify     ${original_candidate}

Create Bridge  Restart and Verify After Recover
    [Documentation]    Create Bridge in up Owner and verify it gets applied from all down instances.
    Create Bridge And Verify    ${new_cluster_list}    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${original_candidate}

To check the first node up and second Restart and third down Instance
    [Documentation]    TO virify the node are created  are not to check the list.
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Kill Multiple Controllers    ${new_cluster_list}
    ${new_cluster_list}    Create Controller Index List
    Set Suite Variable    ${new_cluster_list}
    Take Ovsdb Device Link Up and Verify     ${new_cluster_list}
    Take Ovsdb Device Link Up and Verify     ${original_owner}
    Take Ovsdb Device Link Down and Verify     ${original_owner}
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Take Ovsdb Device Link Down and Verify     ${new_cluster_list}

Create Bridge  Restart and Verify After Recover
    [Documentation]    Create Bridge in up Owner and verify it gets applied from all down instances.
    Create Bridge And Verify    ${new_cluster_list}    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${original_candidate

To check the first node up and second Restart and third Up Instance
    [Documentation]    TO virify the node are created  are not to check the list.
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Kill Multiple Controllers    ${new_cluster_list}
    ${new_cluster_list}    Create Controller Index List
    Set Suite Variable    ${new_cluster_list}
    Take Ovsdb Device Link Up and Verify     ${new_cluster_list}
    Take Ovsdb Device Link Up and Verify     ${original_owner}
    Take Ovsdb Device Link Down and Verify     ${original_owner}
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Take Ovsdb Device Link  Up and Verify     ${new_cluster_list}

Create Bridge  Restart and Verify After Recover
    [Documentation]    Create Bridge in up Owner and verify it gets applied from all down instances.
    Create Bridge And Verify    ${new_cluster_list}    ${original_candidate}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Wait Until Keyword Succeeds    5s    1s    Check Ovsdb Shards Status    ${original_candidate
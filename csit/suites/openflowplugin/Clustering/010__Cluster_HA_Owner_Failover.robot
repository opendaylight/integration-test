*** Settings ***
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in OpenFlow application.
    Check OpenFlow Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}=    Start Mininet Multiple Controllers    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get OpenFlow Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Check Network Operational Information Before Fail
    [Documentation]    Check device is in operational inventory and topology in all cluster instances.
    Check OpenFlow Network Operational Information For One Device    ${original_cluster_list}

Add Configuration In Owner and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Modify Configuration In Owner and Verify Before Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Delete Configuration In Owner and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Add Configuration In Candidate and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Sample Flow and Verify    ${original_cluster_list}    ${original_candidate}

Modify Configuration In Candidate and Verify Before Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Sample Flow and Verify    ${original_cluster_list}    ${original_candidate}

Delete Configuration In Candidate and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Delete Sample Flow and Verify    ${original_cluster_list}    ${original_candidate}

Send RPC Add to Owner and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Send RPC Delete to Owner and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Send RPC Add to Candidate and Verify Before Fail
    [Documentation]    Add Flow in Candidate and verify it gets applied from all instances.
    Send RPC Add Sample Flow and Verify    ${original_cluster_list}    ${original_candidate}

Send RPC Delete to Candidate and Verify Before Fail
    [Documentation]    Delete Flow in Candidate and verify it gets removed from all instances.
    Send RPC Delete Sample Flow and Verify    ${original_cluster_list}    ${original_candidate}

Modify Network And Verify Before Fail
    [Documentation]    Take a link down and verify port status in all instances.
    Take OpenFlow Device Link Down and Verify    ${original_cluster_list}

Restore Network And Verify Before Fail
    [Documentation]    Take the link up and verify port status in all instances.
    Take OpenFlow Device Link Up and Verify    ${original_cluster_list}

Kill Owner Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    Kill Multiple Controllers    ${original_owner}
    ${new_cluster_list}    Create Controller Index List
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in OpenFlow application.
    Check OpenFlow Shards Status    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Get OpenFlow Entity Owner Status For One Device    ${new_cluster_list}
    ${new_candidate}=    Get From List    ${new_candidates_list}    0
    Set Suite Variable    ${new_owner}
    Set Suite Variable    ${new_candidate}

Check Network Operational Information After Fail
    [Documentation]    Check device is in operational inventory and topology in all cluster instances.
    Check OpenFlow Network Operational Information For One Device    ${new_cluster_list}

Add Configuration In Owner and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Sample Flow and Verify    ${new_cluster_list}    ${new_owner}

Modify Configuration In Owner and Verify After Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Sample Flow and Verify    ${new_cluster_list}    ${new_owner}

Delete Configuration In Owner and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Sample Flow and Verify    ${new_cluster_list}    ${new_owner}

Add Configuration In Candidate and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Sample Flow and Verify    ${new_cluster_list}    ${new_candidate}

Modify Configuration In Candidate and Verify After Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Sample Flow and Verify    ${new_cluster_list}    ${new_candidate}

Delete Configuration In Candidate and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Sample Flow and Verify    ${new_cluster_list}    ${new_candidate}

Send RPC Add to Owner and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Sample Flow and Verify    ${new_cluster_list}    ${new_owner}

Send RPC Delete to Owner and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Sample Flow and Verify    ${new_cluster_list}    ${new_owner}

Send RPC Add to Candidate and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Sample Flow and Verify    ${new_cluster_list}    ${new_candidate}

Send RPC Delete to Candidate and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Sample Flow and Verify    ${new_cluster_list}    ${new_candidate}

Modify Network and Verify After Fail
    [Documentation]    Take a link down and verify port status in all instances.
    Take OpenFlow Device Link Down and Verify    ${new_cluster_list}

Restore Network and Verify After Fail
    [Documentation]    Take the link up and verify port status in all instances.
    Take OpenFlow Device Link Up and Verify    ${new_cluster_list}

Start Old Owner Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    Start Multiple Controllers    300s    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in OpenFlow application.
    Wait Until Keyword Succeeds    5s    1s    Check OpenFlow Shards Status    ${original_cluster_list}

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get OpenFlow Entity Owner Status For One Device    ${original_cluster_list}
    Set Suite Variable    ${new_owner}

Check Network Operational Information After Recover
    [Documentation]    Check device is in operational inventory and topology in all cluster instances.
    Check OpenFlow Network Operational Information For One Device    ${original_cluster_list}

Add Configuration In Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Sample Flow and Verify    ${original_cluster_list}    ${new_owner}

Modify Configuration In Owner and Verify After Recover
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Sample Flow and Verify    ${original_cluster_list}    ${new_owner}

Delete Configuration In Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Sample Flow and Verify    ${original_cluster_list}    ${new_owner}

Add Configuration In Old Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Sample Flow and Verify    ${originalcluster_list}    ${original_owner}

Modify Configuration In Old Owner and Verify After Recover
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Delete Configuration In Old Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Send RPC Add to Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Sample Flow and Verify    ${original_cluster_list}    ${new_owner}

Send RPC Delete to Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Sample Flow and Verify    ${original_cluster_list}    ${new_owner}

Send RPC Add to Old Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Send RPC Delete to Old Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Sample Flow and Verify    ${original_cluster_list}    ${original_owner}

Modify Network and Verify After Recover
    [Documentation]    Take a link down and verify port status in all instances.
    Take OpenFlow Device Link Down and Verify    ${original_cluster_list}

Restore Network and Verify After Recover
    [Documentation]    Take the link up and verify port status in all instances.
    Take OpenFlow Device Link Up and Verify    ${original_cluster_list}

Stop Mininet and Exit
    [Documentation]    Stop mininet and exit connection.
    Stop Mininet And Exit    ${mininet_conn_id}
    Clean Mininet System

Check No Network Operational Information
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances.
    Check No OpenFlow Network Operational Information    ${original_cluster_list}

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

Check OpenFlow Shards Status Before Fail
    [Documentation]    Check Status for all shards in OpenFlow application.
    Check OpenFlow Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}=    Start Mininet Multiple Controllers    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get Cluster Entity Owner Status    ${original_cluster_list}
    ...    openflow    openflow:1
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Check Network Operational Information Before Fail
    [Documentation]    Check device is in operational inventory and topology in all cluster instances.
    Check Network Operational Information    ${original_cluster_list}

Add Flow In Owner and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Flow and Verify    ${original_cluster_list}    ${original_owner}

Modify Flow In Owner and Verify Before Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Flow and Verify    ${original_cluster_list}    ${original_owner}

Delete Flow In Owner and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Flow and Verify    ${original_cluster_list}    ${original_owner}

Add Flow In Candidate and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Flow and Verify    ${original_cluster_list}    ${original_candidate}

Modify Flow In Candidate and Verify Before Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Flow and Verify    ${original_cluster_list}    ${original_candidate}

Delete Flow In Candidate and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Delete Flow and Verify    ${original_cluster_list}    ${original_candidate}

Send RPC Add Flow to Owner and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Flow and Verify    ${original_cluster_list}    ${original_owner}

Send RPC Delete Flow to Owner and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Flow and Verify    ${original_cluster_list}    ${original_owner}

Send RPC Add Flow to Candidate and Verify Before Fail
    [Documentation]    Add Flow in Candidate and verify it gets applied from all instances.
    Send RPC Add Flow and Verify    ${original_cluster_list}    ${original_candidate}

Send RPC Delete Flow to Candidate and Verify Before Fail
    [Documentation]    Delete Flow in Candidate and verify it gets removed from all instances.
    Send RPC Delete Flow and Verify    ${original_cluster_list}    ${original_candidate}

Take a Link Down and Verify Before Fail
    [Documentation]    Take a link down and verify port status in all instances.
    Take a Link Down and Verify    ${original_cluster_list}

Take a Link Up and Verify Before Fail
    [Documentation]    Take the link up and verify port status in all instances.
    Take a Link Up and Verify    ${original_cluster_list}

Kill Owner Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    Kill Multiple Controllers    ${original_owner}
    ${new_cluster_list}    Create Controller Index List
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Set Suite Variable    ${new_cluster_list}

Check OpenFlow Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in OpenFlow application.
    Check OpenFlow Shards Status    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get Cluster Entity Owner Status    ${new_cluster_list}
    ...    openflow    openflow:1
    Remove Values From List    ${new_candidates_list}    ${original_owner}
    ${new_candidate}=    Get From List    ${new_candidates_list}    0
    Set Suite Variable    ${new_owner}
    Set Suite Variable    ${new_candidate}

Check Network Operational Information After Fail
    [Documentation]    Check device is in operational inventory and topology in all cluster instances.
    Check Network Operational Information    ${new_cluster_list}

Add Flow In Owner and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Flow and Verify    ${new_cluster_list}    ${new_owner}

Modify Flow In Owner and Verify After Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Flow and Verify    ${new_cluster_list}    ${new_owner}

Delete Flow In Owner and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Flow and Verify    ${new_cluster_list}    ${new_owner}

Add Flow In Candidate and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Add Flow and Verify    ${new_cluster_list}    ${new_candidate}

Modify Flow In Candidate and Verify After Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    Modify Flow and Verify    ${new_cluster_list}    ${new_candidate}

Delete Flow In Candidate and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    Delete Flow and Verify    ${new_cluster_list}    ${new_candidate}

Send RPC Add Flow to Owner and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Flow and Verify    ${new_cluster_list}    ${new_owner}

Send RPC Delete Flow to Owner and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Flow and Verify    ${new_cluster_list}    ${new_owner}

Send RPC Add Flow to Candidate and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    Send RPC Add Flow and Verify    ${new_cluster_list}    ${new_candidate}

Send RPC Delete Flow to Candidate and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    Send RPC Delete Flow and Verify    ${new_cluster_list}    ${new_candidate}

Take a Link Down and Verify After Fail
    [Documentation]    Take a link down and verify port status in all instances.
    Take a Link Down and Verify    ${new_cluster_list}

Take a Link Up and Verify After Fail
    [Documentation]    Take the link up and verify port status in all instances.
    Take a Link Up and Verify    ${new_cluster_list}

Stop Mininet and Exit
    [Documentation]    Stop mininet and exit connection.
    Stop Mininet And Exit    ${mininet_conn_id}
    Clean Mininet System

Check No Network Operational Information
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances.
    Check No Network Operational Information    ${new_cluster_list}

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

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Start OVS Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Create Bridge Manually In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${original_cluster_list}    ${original_owner}

Add Port Manually In Owner and Verify Before Fail
    [Documentation]    Add Port in Owner and verify it gets applied from all instances.
    Add Port To The Manual Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create Bridge Via Controller In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create Port Via Controller In Owner and Verify Before Fail
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Via Controller    ${original_cluster_list}    ${original_owner}

Modify the destination IP of Port Before Fail
    [Documentation]    This will modify the dst ip of existing port
    Modify the destination IP of Port    ${original_cluster_list}    ${original_owner}

Get Operational Topology with modified Port Before Fail
    [Documentation]    This request will fetch the operational topology after the modified port is added to the bridge
    Get Operational Topology with modified Port    ${original_cluster_list}    ${original_owner}

Delete the Port Before Fail
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port And Verify    ${original_cluster_list}    ${original_owner}

Delete the Bridge In Owner and Verify Before Fail
    [Documentation]    This request will delete the bridge node from the operational data store.
    Delete Bridge Manually And Verify    ${original_cluster_list}    ${original_owner}

Delete Bridge Via Rest Call And Verify In Owner Before Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Via Rest Call And Verify    ${original_cluster_list}    ${original_owner}

Kill Owner Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    Kill Multiple Controllers    ${original_owner}
    ${new_cluster_list}    Create Controller Index List
    Remove Values From List    ${new_cluster_list}    ${original_owner}
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

Modify the destination IP of Port After Fail
    [Documentation]    This will modify the dst ip of existing port
    Modify the destination IP of Port    ${new_cluster_list}    ${new_owner}    AfterFail

Get Operational Topology with modified Port After Fail
    [Documentation]    This request will fetch the operational topology after the modified port is added to the bridge
    Get Operational Topology with modified Port    ${new_cluster_list}    ${new_owner}    AfterFail

Delete the Port After Fail
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port And Verify    ${new_cluster_list}    ${new_owner}    AfterFail

Delete the Bridge In Owner and Verify After Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Manually And Verify    ${new_cluster_list}    ${new_owner}

Delete Bridge Via Rest Call And Verify In Owner After Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Via Rest Call And Verify    ${new_cluster_list}    ${new_owner}

Start Old Owner Instance
    [Documentation]    Start Owner Instance and verify it is active
    Start Multiple Controllers    300s    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status After Cluster Event    ${original_cluster_list}

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    Set Suite Variable    ${new_owner}

Create Bridge Manually In Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${original_cluster_list}    ${new_owner}

Add Port Manually In Owner and Verify After Recover
    [Documentation]    Add Port in Owner and verify it gets applied from all instances.
    Add Port To The Manual Bridge And Verify    ${original_cluster_list}    ${new_owner}

Create Bridge Via Controller In Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${new_owner}

Verify Bridge in Restarted Node Which Is Killed Earlier
    [Documentation]    Verify Bridge in Restarted node, which is created when the node is down.
    Verify Bridge in Restarted Node    ${original_cluster_list}

Create Port Via Controller In Owner and Verify After Recover
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Via Controller    ${original_cluster_list}    ${new_owner}

Verify Port in Restarted Node Which Is Killed Earlier
    [Documentation]    Verify Port in Restarted node, which is created when the node is down.
    Verify Port in Restarted Node    ${original_cluster_list}

Modify the destination IP of Port After Recover
    [Documentation]    This will modify the dst ip of existing port
    Modify the destination IP of Port    ${original_cluster_list}    ${new_owner}

Get Operational Topology with modified Port After Recover
    [Documentation]    This request will fetch the operational topology after the modified port is added to the bridge
    Get Operational Topology with modified Port    ${original_cluster_list}    ${new_owner}

Delete the Port After Recover
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port And Verify    ${original_cluster_list}    ${new_owner}

Delete the Bridge In Owner and Verify After Recover
    [Documentation]    This request will delete the bridge node from the operational data store.
    Delete Bridge Manually And Verify    ${original_cluster_list}    ${new_owner}

Delete Bridge Via Rest Call And Verify In Owner After Recover
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Via Rest Call And Verify    ${original_cluster_list}    ${new_owner}

Create Bridge Manually In Old Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${original_cluster_list}    ${original_owner}

Add Port Manually In Old Owner and Verify After Recover
    [Documentation]    Add Port in Owner and verify it gets applied from all instances.
    Add Port To The Manual Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create Bridge Via Controller In Old Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create Port Via Controller In Old Owner and Verify After Recover
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Via Controller    ${original_cluster_list}    ${original_owner}

Modify the destination IP of Port After Recover
    [Documentation]    This will modify the dst ip of existing port
    Modify the destination IP of Port    ${original_cluster_list}    ${original_owner}

Get Operational Topology with modified Port After Recover
    [Documentation]    This request will fetch the operational topology after the modified port is added to the bridge
    Get Operational Topology with modified Port    ${original_cluster_list}    ${original_owner}

Delete the Port After Recover
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port And Verify    ${original_cluster_list}    ${original_owner}

Delete the Bridge In Old Owner and Verify After Recover
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Manually And Verify    ${original_cluster_list}    ${original_owner}

Delete Bridge Via Rest Call And Verify In Old Owner After Recover
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Via Rest Call And Verify    ${original_cluster_list}    ${original_owner}



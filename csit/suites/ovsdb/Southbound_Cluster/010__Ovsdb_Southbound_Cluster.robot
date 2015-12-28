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

${OVSDB_PORT}     6634
@{node_list}      ${BRIDGE}    vx1

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

Create Bridge Manually In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${original_cluster_list}    ${original_owner}

Create Bridge Via Controller In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create a Topology in OVSDB node
    [Documentation]    Create topology in OVSDB and ready it for further tests.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl service openvswitch start
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port ${BRIDGE} vx1 -- set Interface vx1 type=vxlan
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:6634

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${CONFIG_TOPO_API}    ${list}

Delete the Bridge In Owner and Verify Before Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge And Verify    ${original_cluster_list}    ${original_owner}

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

Create Bridge Manually In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${new_cluster_list}    ${new_owner}

Create Bridge Via Controller In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${new_cluster_list}    ${new_owner}

Delete the Bridge In Owner and Verify After Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge And Verify    ${original_cluster_list}    ${original_owner}

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

Create Bridge Manually In Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${original_cluster_list}    ${new_owner}

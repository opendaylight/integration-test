*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDBPORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${BRIDGE}         br01
@{netvirt}        1

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
    Log    ${mininet_conn_id}

Check OVSDB  is created
    [Documentation]    Check if the controller is running before sending restconf requests
    [Tags]    Check controller reachability
    ${node}    Create Dictionary    node-id=ovsdb://uuid/
     Wait Until Keyword Succeeds    300s    4s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${node}    ${OPERATIONAL_TOPO_API}

Check netvirt is Created
    [Documentation]    Check if the netvirt piece has been loaded into the karaf instance
    [Tags]    Ensure netvirt is loaded
    ${topology-id}    Create Dictionary    netvirt=1
    Wait Until Keyword Succeeds    300s    4s    Check Item Occurrence At URI In Cluster       ${original_cluster_list}    ${topology-id}    ${OPERATIONAL_NODES_NETVIRT}


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
${OVSDB_PORT}     6640
${BRIDGE}         br01
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${MININET}:${OVSDB_PORT}    ${MININET}    ${OVSDB_PORT}    br-int

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    ${controller_list}    Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}
    Set Suite Variable    ${controller_list}
    Log    ${controller_list}
    ${controller_1}=    Get from List    ${controller_list}    0
    Set Suite Variable    ${controller_1}
    Log    ${controller_1}
    ${controller_2}=    Get from List    ${controller_list}    1
    Set Suite Variable    ${controller_2}
    Log    ${controller_2}
    ${controller_3}=    Get from List    ${controller_list}    2
    Set Suite Variable    ${controller_3}
    Log    ${controller_3}


Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Create a Bridge In Config DataStore
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge_3node.json
    Log    ${sample}
    ${sample1}    Replace String    ${sample}    tcp:controller1:6633    tcp:${controller_1}:6653
    Log    ${sample1}
    ${sample2}    Replace String    ${sample1}    tcp:controller2:6633    tcp:${controller_2}:6653
    Log    ${sample2}
    ${sample3}    Replace String    ${sample2}    tcp:controller3:6633    tcp:${controller_3}:6653
    Log    ${sample3}
    ${sample4}    Replace String    ${sample3}    127.0.0.1    ${MININET}
    Log    ${sample4}
    ${sample5}    Replace String    ${sample4}    br01    ${BRIDGE}
    Log    ${sample5}
    ${body}    Replace String    ${sample5}    61644    ${OVSDB_PORT}
    Log    ${body}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get a Bridge In Operational DataStore
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the operational data store
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

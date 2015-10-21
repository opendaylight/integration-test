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
${OVSDB_PORT}     6634
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
    ${mininet_conn_id}=    Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Create a Bridge In Config DataStore
    [Documentation]    This will create bridge on the specified OVSDB node.
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

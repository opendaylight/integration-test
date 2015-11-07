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
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://uuid/
@{netvirt}        1

*** Test Cases ***
Create Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Add Multiple Managers to OVS  ${MININET}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Check netvirt is loaded
    [Documentation]    Check if the netvirt piece has been loaded into the karaf instance
    [Tags]    Check netvirt is loaded
    Wait Until Keyword Succeeds    5s    4s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${netvirt}    ${OPERATIONAL_NODES_NETVIRT}
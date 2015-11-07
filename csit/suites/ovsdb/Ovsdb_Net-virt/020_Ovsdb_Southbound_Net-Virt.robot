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
${ODLREST}        /controller/nb/v2/neutron
${OVSDB_PORT}     6640
${OF_PORT}        6653
@{node_list}      ovsdb://uuid/
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

Ensure controller is running
    [Documentation]    Check if the cluster controllers are running before sending restconf requests
    [Tags]    Check controller reachability
    ${node}    Create Dictionary    node-id=1
     Wait Until Keyword Succeeds    300s    4s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${node}    ${OPERATIONAL_TOPO_API}

Check netvirt is Created
    [Documentation]    Check if the netvirt piece has been loaded into the cluster karaf instance
    [Tags]    Ensure netvirt is loaded
    ${topology-id}    Create Dictionary    netvirt=1
    Wait Until Keyword Succeeds    300s    4s    Check Item Occurrence At URI In Cluster       ${original_cluster_list}    ${topology-id}    ${OPERATIONAL_NODES_NETVIRT}

Get bridge setup at controller1
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Controller "tcp:${CONTROLLER1}:${OF_PORT}"
    Should Contain    ${output}    Bridge br-int

Get bridge setup at controller2
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Controller "tcp:${CONTROLLER2}:${OF_PORT}"
    Should Contain    ${output}    Bridge br-int
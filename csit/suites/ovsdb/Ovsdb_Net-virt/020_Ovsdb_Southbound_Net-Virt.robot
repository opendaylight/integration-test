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
${config_table_0}    ${CONFIG_NODES_API}/node/openflow:1/table/0
${operational_table_0}    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0
${operational_port_1}    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1
${ODLREST}        /controller/nb/v2/neutron
${OVSDB_PORT}     6640
${OF_PORT}        6653
${FLOWS_TABLE_20}    actions=goto_table:20
${FLOW_CONTROLLER}    actions=CONTROLLER:65535
${FLOWS_TABLE_30}    actions=goto_table:30
${FLOWS_TABLE_40}    actions=goto_table:40
${FLOWS_TABLE_50}    actions=goto_table:50
${FLOWS_TABLE_60}    actions=goto_table:60
${FLOWS_TABLE_70}    actions=goto_table:70
${FLOWS_TABLE_80}    actions=goto_table:80
${FLOWS_TABLE_90}    actions=goto_table:90
${FLOWS_TABLE_100}    actions=goto_table:100
${FLOWS_TABLE_110}    actions=goto_table:110
${FLOW_DROP}      actions=drop
${PING_NOT_CONTAIN}    Destination Host Unreachable
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
    ${mininet_conn_id}    Start Mininet Multiple Controllers   ${MININET}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Check netvirt is Created
    [Documentation]    Check if the netvirt piece has been loaded into the cluster karaf instance
    [Tags]    Ensure netvirt is loaded
    ${topology-id}    Create Dictionary    netvirt=1
    Wait Until Keyword Succeeds    300s    4s    Check Item Occurrence At URI In Cluster       ${original_cluster_list}    ${topology-id}    ${OPERATIONAL_NODES_NETVIRT}

Get bridge setup
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    Log    ${TOOLS_SYSTEM_IP}
    Log    ${CONTROLLER}
    Log    ${CONTROLLER1}
    Log    ${CONTROLLER2}
    ${output}   Send Mininet Command    ${mininet_conn_id}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Controller "tcp:${CONTROLLER}:${OF_PORT}"
    Should Contain    ${output}    Bridge br-int

Get port setup
    [Documentation]    This will check the port br-int has been created
    [Tags]    OVSDB netvirt
    ${output}   Send Mininet Command    ${mininet_conn_id}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Port br-int

Get interface setup
    [Documentation]    This verify the interface br-int has been created
    [Tags]    OVSDB netvirt
    ${output}   Send Mininet Command    ${mininet_conn_id}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Interface br-int


Get the bridge flows
    [Documentation]    This request fetch the OF13 flow tables to verify the flows are correctly added
    [Tags]    OVSDB netvirt
    ${output}   Send Mininet Command    ${mininet_conn_id}    sudo ovs-ofctl -O Openflow13 dump-flows br-int
    Log    ${output}
    Should Contain    ${output}    ${FLOWS_TABLE_20}
    Should Contain    ${output}    ${FLOW_CONTROLLER}
    Should Contain    ${output}    ${FLOWS_TABLE_30}
    Should Contain    ${output}    ${FLOWS_TABLE_40}
    Should Contain    ${output}    ${FLOWS_TABLE_50}
    Should Contain    ${output}    ${FLOWS_TABLE_60}
    Should Contain    ${output}    ${FLOWS_TABLE_70}
    Should Contain    ${output}    ${FLOWS_TABLE_80}
    Should Contain    ${output}    ${FLOWS_TABLE_90}
    Should Contain    ${output}    ${FLOWS_TABLE_100}
    Should Contain    ${output}    ${FLOWS_TABLE_110}
    Should Contain    ${output}    ${FLOW_DROP}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${options}    --topo tree,1 --switch ovsk,protocols=OpenFlow13
    ${custom}    ${EMPTY}
    ${mininet_conn_id}    Add Multiple Managers to OVS    ${mininet}    ${controller_index_list}    ${OVSDB_PORT}
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Get bridge setup
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    Log    ${TOOLS_SYSTEM_IP}
    Log    ${CONTROLLER}
    Log    ${CONTROLLER1}
    Log    ${CONTROLLER2}
    ${output}   Send Mininet Command    ${mininet_conn_id}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Controller "tcp:${CONTROLLER}:${OF_PORT}"
    Should Contain    ${output}    Bridge br-int
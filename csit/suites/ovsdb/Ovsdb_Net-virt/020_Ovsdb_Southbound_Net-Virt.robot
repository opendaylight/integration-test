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
@{FLOW_TABLE_LIST}    actions=goto_table:20    actions=CONTROLLER:65535    actions=goto_table:30    actions=goto_table:40    actions=goto_table:50    actions=goto_table:60    actions=goto_table:70
...               actions=goto_table:80    actions=goto_table:90    actions=goto_table:100    actions=goto_table:110    actions=drop

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

Get bridge setup
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Bridge br-int

Get port setup
    [Documentation]    This will check the port br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Port br-int

Get interface setup
    [Documentation]    This verify the interface br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Interface br-int

Get the bridge flows
    [Documentation]    This request fetch the OF13 flow tables to verify the flows are correctly added
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-ofctl -O Openflow13 dump-flows br-int
    Log    ${output}
    : FOR    ${flows}    IN    @{FLOW_TABLE_LIST}
    \    Should Contain    ${output}    ${flows}

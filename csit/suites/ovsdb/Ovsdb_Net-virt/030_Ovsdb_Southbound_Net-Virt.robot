*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
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
@{FLOW_TABLE_LIST}    actions=goto_table:20    actions=CONTROLLER:65535    actions=goto_table:30    actions=goto_table:40    actions=goto_table:50    actions=goto_table:60    actions=goto_table:70    actions=goto_table:80    actions=goto_table:90    actions=goto_table:100    actions=goto_table:110    actions=drop
${OF_PORT}    6653
${PING_NOT_CONTAIN}    Destination Host Unreachable
@{node_list}      ovsdb://uuid/

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Verify Net-virt Features
    [Documentation]    Installing Net-virt Console related features (odl-ovsdb-openstack)
    Verify Feature Is Installed    odl-ovsdb-openstack

Check mininet
   [Documentation]    Check wheather br-int available or not
   ${list}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl list-br
   Log    ${list}

Connect to Mininet
    [Documentation]    Connecting to mininet
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_1_IP}:${OVSDB_PORT} tcp:${ODL_SYSTEM_2_IP}:${OVSDB_PORT} tcp:${ODL_SYSTEM_3_IP}:${OVSDB_PORT}
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Log    ${output}
    ${pingresult}    Run Command On Remote System    ${MININET}    ping ${ODL_SYSTEM_1_IP} -c 4
    Should Not Contain    ${pingresult}    ${PING_NOT_CONTAIN}

Check operational topology
   [Documentation]    Check the operational topology
   ${uuid}=    Set Variable    ${EMPTY}
   ${resp}=    RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1
   Log    ${resp.content}
   Should Be Equal As Strings    ${resp.status_code}    200

Check net-virt
  [Documentation]    Check net-virt created or not
  Get OVSDB UUID    ${mininet}    ${ODL_SYSTEM_1_IP}

Make the OVS instance to listen for connection
    [Documentation]    Connect OVS to ODL
    [Tags]    OVSDB netvirt
    Clean Up Ovs    ${MININET}
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager tcp:${CONTROLLER}:${OVSDB_PORT}
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    ${pingresult}    Run Command On Remote System    ${MININET}    ping ${CONTROLLER} -c 4
    Should Not Contain    ${pingresult}    ${PING_NOT_CONTAIN}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}

Get manager connection
    [Documentation]    This will verify if the OVS manager is connected
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    ${lines}=    Get Lines Containing String    ${output}    is_connected
    ${manager}=    Get Line    ${lines}    0
    Should Contain    ${manager}    true

Get controller connection
    [Documentation]    This will verify if the OpenFlow controller is connected on all bridges
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    ${lines}=    Get Lines Containing String    ${output}    is_connected
    ${list}=    Split String    ${lines}    \n
    Remove From List    ${list}    0
    : FOR    ${controller}    IN    @{list}
    \    Should Contain    ${controller}    true

Get bridge setup
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Should Contain    ${output}    Controller "tcp:${CONTROLLER}:${OF_PORT}"
    Should Contain    ${output}    Bridge br-int

Get port setup
    [Documentation]    This will check the port br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Should Contain    ${output}    Port br-int

Get interface setup
    [Documentation]    This verify the interface br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Should Contain    ${output}    Interface br-int

Get the bridge flows
    [Documentation]    This request fetch the OF13 flow tables to verify the flows are correctly added
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-ofctl -O Openflow13 dump-flows br-int
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
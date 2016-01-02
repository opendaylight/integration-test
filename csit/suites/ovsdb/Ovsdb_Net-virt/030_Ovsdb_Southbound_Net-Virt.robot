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
   Wait Until Keyword Succeeds    8s    2s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${node_list}    ${OPERATIONAL_TOPO_API}
   Get OVSDB UUID    ${mininet}    ${ODL_SYSTEM_1_IP}
   ${uuid}=    Set Variable    ${EMPTY}
   ${resp}=    RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1
   Log    ${resp.content}
   Should Be Equal As Strings    ${resp.status_code}    200
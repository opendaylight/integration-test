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
@{node-id}    ovsdb://uuid/
${PING_NOT_CONTAIN}    Destination Host Unreachable

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Verify Net-virt Features
    [Documentation]    Installing Net-virt Console related features (odl-ovsdb-openstack)
    Verify Feature Is Installed    odl-ovsdb-openstack
    Verify Feature Is Installed    odl-mdsal-clustering-commons
    Verify Feature Is Installed    odl-mdsal-clustering
    Verify Feature Is Installed    odl-ovsdb-southbound-impl
    Verify Feature Is Installed    odl-ovsdb-library
    Verify Feature Is Installed    odl-ovsdb-all

Check mininet
   [Documentation]    Check wheather br-int available or not
   ${list}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl list-br
   Log    ${list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Add Multiple Managers to OVS  ${MININET}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Ping Mininet with Controllers
    [Documentation]    Checking ping with mininet and controller
    ${pingresult}    Run Command On Remote System    ${MININET}    ping ${ODL_SYSTEM_1_IP} -c 4
    Should Not Contain    ${pingresult}    ${PING_NOT_CONTAIN}

Check Cluster status
    [Documentation]    Check Status of cluster
    Wait Until Keyword Succeeds    40s    40s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${node-id}    ${OPERATIONAL_TOPO_API}

Get manager connection
    [Documentation]    This will verify if the OVS manager is connected
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    ${lines}=    Get Lines Containing String    ${output}    is_connected
    ${manager}=    Get Line    ${lines}    0
    Should Contain    ${manager}    true

Check Cluster status
    [Documentation]    Check Status of cluster
    Wait Until Keyword Succeeds    40s    40s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${node-id}    ${OPERATIONAL_TOPO_API}

Get bridge setup
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    ${output}   Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Bridge br-int

Get port setup
    [Documentation]    This will check the port br-int has been created
    [Tags]    OVSDB netvirt
    ${output}   Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Port br-int

Get interface setup
    [Documentation]    This verify the interface br-int has been created
    [Tags]    OVSDB netvirt
    ${output}   Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Interface br-int


Get the bridge flows
    [Documentation]    This request fetch the OF13 flow tables to verify the flows are correctly added
    [Tags]    OVSDB netvirt
    ${output}   Run Command On Remote System    ${MININET}    sudo ovs-ofctl -O Openflow13 dump-flows br-int
    Log    ${output}
    : FOR    ${flows}    IN    @{FLOW_TABLE_LIST}
    \    Should Contain    ${output}    ${flows}
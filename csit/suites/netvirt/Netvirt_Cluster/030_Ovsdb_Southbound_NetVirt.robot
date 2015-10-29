*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    Delete All Sessions
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{FLOW_TABLE_LIST}    actions=goto_table:20    actions=CONTROLLER:65535    actions=goto_table:30    actions=goto_table:40    actions=goto_table:50    actions=goto_table:60    actions=goto_table:70
...               actions=goto_table:80    actions=goto_table:90    actions=goto_table:100    actions=goto_table:110    actions=drop

*** Test Cases ***
Verify Net-virt Features
    [Documentation]    Installing Net-virt Console related features (odl-ovsdb-openstack)
    KarafKeywords.Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_1_IP}
    KarafKeywords.Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_2_IP}
    KarafKeywords.Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_3_IP}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Ovsdb.Add Multiple Managers to OVS
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Get manager connection
    [Documentation]    This will verify if the OVS manager is connected
    [Tags]    OVSDB netvirt
    Ovsdb.Verify OVS Reports Connected

Check Operational topology
    [Documentation]    Check Operational topology
    ${dictionary}=    Create Dictionary    ovsdb://uuid/=5
    Wait Until Keyword Succeeds    20s    2s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_TOPO_API}    dictionary=${dictionary}

Get bridge setup
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    ${output}    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Bridge br-int

Get port setup
    [Documentation]    This will check the port br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Port br-int

Get interface setup
    [Documentation]    This verify the interface br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    Should Contain    ${output}    Interface br-int

Get the bridge flows
    [Documentation]    This request fetch the OF13 flow tables to verify the flows are correctly added
    [Tags]    OVSDB netvirt
    ${output}    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-ofctl -O Openflow13 dump-flows br-int
    Log    ${output}
    : FOR    ${flows}    IN    @{FLOW_TABLE_LIST}
    \    Should Contain    ${output}    ${flows}

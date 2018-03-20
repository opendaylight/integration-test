*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       OVSDB.Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        Southbound
Library           RequestsLibrary
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${BRIDGE1}        ovscon_br1
${BRIDGE2}        ovscon_br2
@{NODE_LIST}      ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${TOOLS_SYSTEM_IP}    ${OVSDB_NODE_PORT}
${OVSDB_UUID}     ${EMPTY}

*** Test Cases ***
Connecting an OVS instance to the controller
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT}
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected

Get Operational Topology to verify the ovs instance is connected to the controller
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list} =    BuiltIn.Create List    ovsdb://uuid    "remote-ip":"${TOOLS_SYSTEM_IP}"    "local-port":${OVSDBPORT}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True
    ${OVSDB_UUID} =    OVSDB.Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    BuiltIn.Set Suite Variable    ${OVSDB_UUID}

Verify OVS Not In Config Topology
    [Documentation]    This request will fetch the configuration topology from configuration data store
    Utils.Check For Elements Not At URI    ${CONFIG_TOPO_API}    ${NODE_LIST}    pretty_print_json=True

Create bridge manually
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE1}

Get Operational Topology to verify the bridge has been added
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list} =    BuiltIn.Create List    ${BRIDGE1}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True

Get Config Topology to verify the manually added bridge is not added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Should Not Contain    ${resp.content}    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}/bridge/${BRIDGE1}

Create a Bridge through controller
    [Documentation]    This will create bridge on the specified OVSDB node.
    OVSDB.Add Bridge To Ovsdb Node    uuid/${OVSDB_UUID}    ${TOOLS_SYSTEM_IP}    ${BRIDGE2}    0000000000000002

Get Operational Topology to verify the bridge has been added through rest call
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list} =    BuiltIn.Create List    ${BRIDGE2}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True

Get Config Topology to verify the entry added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Should Contain    ${resp.content}    ovsdb://uuid/${OVSDB_UUID}/bridge/${BRIDGE2}

Create bridge of already added bridge
    [Documentation]    This will add bridge to the config datastore
    OVSDB.Add Bridge To Ovsdb Node    uuid/${OVSDB_UUID}    ${TOOLS_SYSTEM_IP}    ${BRIDGE1}    0000000000000001

Get Config Topology to verify the entry of existing bridge added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Should Contain    ${resp.content}    ovsdb://uuid/${OVSDB_UUID}/bridge/${BRIDGE1}

Delete bridge manually
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-br ${BRIDGE2}

Get Operational Topology to verify the bridge has been deleted manually
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list} =    BuiltIn.Create List    ${BRIDGE2}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True

Config Topology Still Contains Bridge
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Should Contain    ${resp.content}    ovsdb://uuid/${OVSDB_UUID}/bridge/${BRIDGE2}

Delete the Bridge through rest call
    [Documentation]    This request will delete the bridge node from the config data store.
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${OVSDB_UUID}%2Fbridge%2F${BRIDGE2}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    @{list} =    BuiltIn.Create List    ${BRIDGE2}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True

Trunk And Vlan Tag Is Removed From Operational
    [Documentation]    Verify that when the vlan tag is added and removed from an ovs port, it should be accurately reflected
    ...    in the operational store. Also verify that when all trunks are cleared from ovs, it's accurate in operational.
    [Tags]    8529
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br vlan-tag-br
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port vlan-tag-br vlan-tag-port
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set port vlan-tag-port tag=81
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set port vlan-tag-port trunks=[181,182]
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected
    OVSDB.Collect OVSDB Debugs
    @{list}    BuiltIn.Create List    vlan-tag-br    vlan-tag-port    "ovsdb:vlan-tag":81    "trunk":181    "trunk":182
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl clear port vlan-tag-port tag
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl remove port vlan-tag-port trunks 181
    @{list}    BuiltIn.Create List    "ovsdb:vlan-tag":81    "trunk":181
    OVSDB.Collect OVSDB Debugs
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl clear port vlan-tag-port trunks
    @{list}    BuiltIn.Create List    "ovsdb:vlan-tag":81    "trunk":181    "trunk":182
    OVSDB.Collect OVSDB Debugs
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}    pretty_print_json=True
    [Teardown]    Builtin.Run Keywords    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ...    AND    Utils.Report_Failure_Due_To_Bug    OVSDB-413

Check For Bug 4756
    [Documentation]    bug 4756 has been seen in the OVSDB Southbound suites. This test case should be one of the last test
    ...    case executed.
    Utils.Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    SimpleShardDataTreeCohort.*Unexpected failure in validation phase
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4756

Check For Bug 4794
    [Documentation]    bug 4794 has been seen in the OVSDB Southbound suites. This test case should be one of the last test
    ...    case executed.
    Utils.Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Shard.*shard-topology-operational An exception occurred while preCommitting transaction
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4794

*** Keywords ***
Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    @{uris} =    Builtin.Create List    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${OVSDB_UUID}%2Fbridge%2F${BRIDGE1}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${OVSDB_UUID}%2Fbridge%2F${BRIDGE2}
    OVSDB.Suite Teardown    ${uris}

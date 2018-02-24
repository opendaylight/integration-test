*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       OVSDB.Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        Southbound
Library           RequestsLibrary
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${BRIDGE}         ovsconf_exit_br
${PORT1}          vx1
${PORT2}          vx2
@{NODE_LIST}      ${BRIDGE}    ${PORT1}

*** Test Cases ***
Create a Topology in OVSDB node
    [Documentation]    Create topology in OVSDB and ready it for further tests
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port ${BRIDGE} ${PORT1} -- set Interface ${PORT1} type=vxlan options:remote_ip=192.168.1.11
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:6634

Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    OVSDB.Connect To Ovsdb Node    ${TOOLS_SYSTEM_IP}

Get Operational Topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${NODE_LIST}    pretty_print_json=True
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5221

Verify Bridge Port Not In Config DS
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    @{list} =    BuiltIn.Create List    ${PORT1}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${CONFIG_TOPO_API}    ${list}    pretty_print_json=True

Create bridge of already added bridge
    [Documentation]    This will add bridge to the config datastore
    OVSDB.Add Bridge To Ovsdb Node    ${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${TOOLS_SYSTEM_IP}    ${BRIDGE}    0000000000000030

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    @{list} =    BuiltIn.Create List    ${BRIDGE}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${CONFIG_TOPO_API}    ${list}    pretty_print_json=True

Create Port of already added port in OVSDB
    [Documentation]    This will add port/interface to the config datastore
    OVSDB.Add Termination Point    ${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${BRIDGE}    ${PORT1}    10.0.0.10

Get Config Topology with Bridge and Port
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${CONFIG_TOPO_API}    ${NODE_LIST}    pretty_print_json=True

Modify the destination IP of Port
    [Documentation]    This will modify the dst ip of existing port
    OVSDB.Add Termination Point    ${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${BRIDGE}    ${PORT1}    10.0.0.19

Get Operational Topology with modified Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list} =    BuiltIn.Create List    ${BRIDGE}    ${PORT1}    10.0.0.19
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}    pretty_print_json=True
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5221

Create Port and attach to a Bridge
    [Documentation]    This request will creates port/interface and attach it to the specific bridge
    OVSDB.Add Termination Point    ${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${BRIDGE}    ${PORT2}    10.0.0.121

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list} =    BuiltIn.Create List    ${BRIDGE}    ${PORT2}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}    pretty_print_json=True
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5221

Delete the Port1
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_NODE_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/${PORT1}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology after deletion of Port1
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list} =    BuiltIn.Create List    ${PORT1}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}    pretty_print_json=True

Delete the Port2
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_NODE_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/${PORT2}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology after Deletion of Port2
    [Documentation]    This request will fetch the operational topology after the Port is deleted
    @{list} =    BuiltIn.Create List    ${PORT2}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}    pretty_print_json=True

Delete the Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_NODE_CONFIG_API}%2Fbridge%2F${BRIDGE}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    @{list} =    BuiltIn.Create List    ${BRIDGE}    ${PORT1}    ${PORT2}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}    pretty_print_json=True

Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_NODE_CONFIG_API}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology after Deletion of OVSDB Node
    [Documentation]    This request will fetch the operational topology after the OVSDB node is deleted
    @{list} =    BuiltIn.Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${BRIDGE}    ${PORT1}    ${PORT2}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}    pretty_print_json=True

Check For Bug 4756
    [Documentation]    bug 4756 has been seen in the OVSDB Southbound suites. This test case should be one of the last test
    ...    case executed
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
    @{uris} =    Builtin.Create List    ${SOUTHBOUND_NODE_CONFIG_API}
    OVSDB.Suite Teardown    ${uris}

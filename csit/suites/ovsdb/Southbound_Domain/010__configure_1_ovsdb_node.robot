*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Ovsdb.Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        Southbound
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../Ovsdb.robot

*** Variables ***
${BRIDGE}         ovsconf_br
${PORT}           ovsconf_vx1
${QOS}            QOS-1
${QUEUE}          QUEUE-1
@{NODE_LIST}      ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${TOOLS_SYSTEM_IP}    ${OVSDB_NODE_PORT}

*** Test Cases ***
Make the OVS instance to listen for connection
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_NODE_PORT}

Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    OVSDB.Connect To Ovsdb Node    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected

Get Operational Topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${NODE_LIST}

Create a Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    OVSDB.Add Bridge To Ovsdb Node    ${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${TOOLS_SYSTEM_IP}    ${BRIDGE}    0000000000000040

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    BuiltIn.Should Contain    ${resp.content}    ${BRIDGE}

Get Operational Topology with Bridge
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    @{list} =    BuiltIn.Create List    ${BRIDGE}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Create Port and Attach to a Bridge
    [Documentation]    This request will creates port/interface and attach it to the specific bridge
    OVSDB.Add Termination Point    ${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}    ${BRIDGE}    ${PORT}    10.0.0.10

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list} =    BuiltIn.Create List    ${BRIDGE}    ${PORT}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete the Port
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_NODE_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/${PORT}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Port
    [Documentation]    This request will fetch the operational topology after the Port is deleted
    @{list} =    BuiltIn.Create List    ${PORT}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete the Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_NODE_CONFIG_API}%2Fbridge%2F${BRIDGE}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    @{list} =    BuiltIn.Create List    ${BRIDGE}    ${PORT}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Verify Config Still Has OVS Info
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the node is still in the data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${NODE_LIST}

Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_NODE_CONFIG_API}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology to make sure the connection has been deleted
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list} =    BuiltIn.Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Get Configuration Topology to make sure the connection has been deleted
    [Documentation]    This request will fetch the configuration topology from the connected OVSDB nodes
    @{list} =    BuiltIn.Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI And Print    ${CONFIG_TOPO_API}/topology/ovsdb:1    ${list}

Reconnect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    OVSDB.Connect To Ovsdb Node    ${TOOLS_SYSTEM_IP}

Get Operational Topology After Node Reconnect
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${NODE_LIST}

Get Config Topology After Reconnect
    [Documentation]    This will fetch the configuration topology from configuration data store after reconnect
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${NODE_LIST}

Create OVSDB NODE HOST1
    [Documentation]    This request will create OVSDB NODE HOST1
    OVSDB.Create Ovsdb Node    ${TOOLS_SYSTEM_IP}

Create QOS entry
    [Documentation]    This request will create QOS entry
    OVSDB.Create Qos    ${QOS}

Create Queue entry to the queues list of a ovsdb node
    [Documentation]    This request will creates Queue entry in the queues list of a ovsdb node
    OVSDB.Create Queue    ${QUEUE}

Update existing Queue entry to a OVSDB Node
    [Documentation]    This request will update the existing queue entry to a OVSDB Node
    OVSDB.Create Queue    ${queue}

Update QOS with a Linked queue entry to a OVSDB Node
    [Documentation]    This request will update the QOS entry with a Linked queue entry to a OVSDB Node
    OVSDB.Update Qos    ${QOS}

Get QOS Config Topology with port
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the QOS is added to the data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    BuiltIn.Should Contain    ${resp.content}    ${QOS}

Get QOS Operational Topology with port
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the QOS is added to the data store
    @{list} =    BuiltIn.Create List    ${QOS}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Get Queue Config Topology with port
    [Documentation]    This request will fetch the configuration topology from configuration data store to verify the Queue is added to the data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    BuiltIn.Should Contain    ${resp.content}    ${QUEUE}

Get Queue Operational Topology with port
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the Queue is added to the data store
    @{list} =    BuiltIn.Create List    ${QUEUE}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete a Queue entry from a Qos entry
    [Documentation]    This request will Delete a Queue entry from a Qos entry
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/queue-list/0/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete a QoS entry from a node
    [Documentation]    This request will Delete a QoS entry from a node.
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete a Queue entry from an ovsdb node
    [Documentation]    This request will Delete a Queue entry from an ovsdb node
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${QUEUE}/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete the OVSDB Node HOST1
    [Documentation]    This request will delete the OVSDB node
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Config Topology to verify that deleted configurations are cleaned from config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store to verify OVSDB NODE is deleted frrom the configuration data store
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    BuiltIn.Should Not Contain    ${resp.content}    ovsdb:HOST1

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
    @{uris} =    Builtin.Create List    ${SOUTHBOUND_NODE_CONFIG_API}
    Ovsdb.Suite Teardown    ${uris}

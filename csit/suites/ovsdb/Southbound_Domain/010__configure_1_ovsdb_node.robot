*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Configure 1 OVSDB Node Suite Setup
Suite Teardown    Configure 1 OVSDB Node Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        Southbound
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${OVSDB_PORT}     6634
${BRIDGE}         ovsdb-csit-test-bridge
${QOS}            QOS-1
${QUEUE}          QUEUE-1
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${TOOLS_SYSTEM_IP}    ${OVSDB_PORT}

*** Test Cases ***
Make the OVS instance to listen for connection
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}

Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected

Get Operational Topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}

Create a Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ${BRIDGE}

Get Operational Topology with Bridge
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Create Port and attach to a Bridge
    [Documentation]    This request will creates port/interface and attach it to the specific bridge
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete the Port
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Port
    [Documentation]    This request will fetch the operational topology after the Port is deleted
    @{list}    Create List    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete the Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    @{list}    Create List    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Verify Config Still Has OVS Info
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}

Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology to make sure the connection has been deleted
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Get Configuration Topology to make sure the connection has been deleted
    [Documentation]    This request will fetch the configuration topology from the connected OVSDB nodes
    @{list}    Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${CONFIG_TOPO_API}/topology/ovsdb:1    ${node_list}

Reconnect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Operational Topology After Node Reconnect
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}

Get Config Topology After Reconnect
    [Documentation]    This will fetch the configuration topology from configuration data store after reconnect
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}

Create OVSDB NODE HOST1
    [Documentation]    This request will create OVSDB NODE HOST1 and attach it to the specific bridge
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_node.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${CONFIG_TOPO_API}/topology/ovsdb:1/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create QOS entry
    [Documentation]    This request will create QOS entry
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qos.json
    Log    URL is ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create Queue entry to the queues list of a ovsdb node
    [Documentation]    This request will creates Queue entry in the queues list of a ovsdb node
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_queue.json
    Log    URL is ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${QUEUE}/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${QUEUE}/    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create a QOS and a Linked queue entry to a OVSDB Node
    [Documentation]    This request will create a QOS and a Linked queue entry to a OVSDB Node
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qoslinkedqueue.json
    Log    URL is ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get QOS Config Topology with port
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the QOS is added to the data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    ${QOS}

Get QOS Operational Topology with port
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the QOS is added to the data store
    @{list}    Create List    ${QOS}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Get Queue Config Topology with port
    [Documentation]    This request will fetch the configuration topology from configuration data store to verify the Queue is added to the data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    ${QUEUE}

Get Queue Operational Topology with port
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the Queue is added to the data store
    @{list}    Create List    ${QUEUE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete a Queue entry from a Qos entry
    [Documentation]    This request will Delete a Queue entry from a Qos entry
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/queue-list/0/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete a QoS entry from a node
    [Documentation]    This request will Delete a QoS entry from a node.
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete a Queue entry from an ovsdb node
    [Documentation]    This request will Delete a Queue entry from an ovsdb node
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${QUEUE}/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete the OVSDB Node HOST1
    [Documentation]    This request will delete the OVSDB node
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Config Topology to verify that deleted configurations are cleaned from config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store to verify OVSDB NODE is deleted frrom the configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should not Contain    ${resp.content}    ovsdb:HOST1

Check For Bug 4756
    [Documentation]    bug 4756 has been seen in the OVSDB Southbound suites. This test case should be one of the last test
    ...    case executed.
    Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    SimpleShardDataTreeCohort.*Unexpected failure in validation phase
    [Teardown]    Report_Failure_Due_To_Bug    4756

Check For Bug 4794
    [Documentation]    bug 4794 has been seen in the OVSDB Southbound suites. This test case should be one of the last test
    ...    case executed.
    Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Shard.*shard-topology-operational An exception occurred while preCommitting transaction
    [Teardown]    Report_Failure_Due_To_Bug    4794

*** Keywords ***
Configure 1 OVSDB Node Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Configure 1 OVSDB Node Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Delete All Sessions

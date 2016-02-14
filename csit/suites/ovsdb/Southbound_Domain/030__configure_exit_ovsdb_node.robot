*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Configure Exit OVSDB Node Suite Setup
Suite Teardown    Configure Exit OVSDB Node Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Force Tags        Southbound
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${OVSDB_PORT}     6634
${BRIDGE}         ovsdb-csit-test-bridge
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ${BRIDGE}    vx1

*** Test Cases ***
Create a Topology in OVSDB node
    [Documentation]    Create topology in OVSDB and ready it for further tests
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port ${BRIDGE} vx1 -- set Interface vx1 type=vxlan options:remote_ip=192.168.1.11
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:6634

Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}
    [Teardown]    Report_Failure_Due_To_Bug    5221

Verify Bridge Port Not In Config DS
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    @{list}    Create List    vx1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${CONFIG_TOPO_API}    ${list}

Create bridge of already added bridge
    [Documentation]    This will add bridge to the config datastore
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${CONFIG_TOPO_API}    ${list}

Create Port of already added port in OVSDB
    [Documentation]    This will add port/interface to the config datastore
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    ${sample1}    Replace String    ${sample}    vxlanport    vx1
    ${body}    Replace String    ${sample1}    192.168.0.21    192.168.1.10
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vx1/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vx1/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology with Bridge and Port
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${CONFIG_TOPO_API}    ${node_list}

Modify the destination IP of Port
    [Documentation]    This will modify the dst ip of existing port
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    ${sample1}    Replace String    ${sample}    vxlanport    vx1
    ${body}    Replace String    ${sample1}    192.168.0.21    10.0.0.19
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vx1/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vx1/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology with modified Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    ${BRIDGE}    vx1    10.0.0.19
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}
    [Teardown]    Report_Failure_Due_To_Bug    5221

Create Port and attach to a Bridge
    [Documentation]    This request will creates port/interface and attach it to the specific bridge
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}
    [Teardown]    Report_Failure_Due_To_Bug    5221

Delete the Port1
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vx1/
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after deletion of Port1
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    vx1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Port2
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Port2
    [Documentation]    This request will fetch the operational topology after the Port is deleted
    @{list}    Create List    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    @{list}    Create List    ${BRIDGE}    vxlanport    vx1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of OVSDB Node
    [Documentation]    This request will fetch the operational topology after the OVSDB node is deleted
    @{list}    Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${BRIDGE}    vxlanport    vx1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

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
Configure Exit OVSDB Node Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Configure Exit OVSDB Node Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Delete All Sessions

*** Settings ***
Documentation     WIP: NetVirt scale test
Suite Setup       OVSDB Connection Manager Suite Setup
Suite Teardown    OVSDB Connection Manager Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${OVSDB_PORT}     6634
${BRIDGE1}        ovsdb-csit-test-bridge1
${BRIDGE2}        ovsdb-csit-test-bridge2
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${TOOLS_SYSTEM_IP}    ${OVSDB_PORT}
${NUM_SERVERS}    1
${PORTS_PER_SERVER}    1
${PORTS_PER_NETWORK}    1
${CONCURRENT_NETWORKS}    1
${NETWORKS_PER_ROUTER}    1
${CONCURRENT_ROUTERS}    1
${FLOATING_IP_PER_NUM_PORTS}    0

*** Test Cases ***
Connecting an OVS instance to the controller
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected

Get Operational Topology to verify the ovs instance is connected to the controller
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ovsdb://uuid    "remote-ip":"${TOOLS_SYSTEM_IP}"    "local-port":6640
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    ${ovsdb_uuid}=    Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    Set Suite Variable    ${ovsdb_uuid}

Verify OVS Not In Config Topology
    [Documentation]    This request will fetch the configuration topology from configuration data store
    Check For Elements Not At URI    ${CONFIG_TOPO_API}    ${node_list}

Create bridge manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE1}

Get Operational Topology to verify the bridge has been added
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE1}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Get Config Topology to verify the manually added bridge is not added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should not Contain    ${resp.content}    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}/bridge/${BRIDGE1}

Create a Bridge through controller
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${body}    Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://uuid/${ovsdb_uuid}
    ${body}    Replace String    ${body}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6633
    ${body}    Replace String    ${body}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${body}    br01    ${BRIDGE2}
    ${body}    Replace String    ${body}    61644    ${OVSDB_PORT}
    ${uri}=    Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE2}
    Log    URL is ${uri}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Operational Topology to verify the bridge has been added through rest call
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE2}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Get Config Topology to verify the entry added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://uuid/${ovsdb_uuid}/bridge/${BRIDGE2}

*** Keywords ***
OVSDB Connection Manager Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

OVSDB Connection Manager Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE1}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE2}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Delete All Sessions

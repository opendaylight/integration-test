*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       OVSDB Connection Manager Suite Setup
Suite Teardown    OVSDB Connection Manager Suite Teardown
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
${BRIDGE1}         ovsdb-csit-test-bridge1
${BRIDGE2}         ovsdb-csit-test-bridge2
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${MININET}:${OVSDB_PORT}    ${MININET}    ${OVSDB_PORT}

*** Test Cases ***
Connecting an OVS instance to the controller
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager tcp:${CONTROLLER}:6640

Get Operational Topology to verify the ovs instance is connected to the controller
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ovsdb:1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Verify OVS Not In Config Topology
    [Documentation]    This request will fetch the configuration topology from configuration data store
    Check For Elements Not At URI    ${CONFIG_TOPO_API}    ${node_list}

Create bridge manually
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl add-br ${BRIDGE1}

Get Operational Topology to verify the bridge has been added
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE1}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the manually added bridge is not added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should not Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE1}

Create a Bridge through controller
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE2}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE2}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE2}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology to verify the bridge has been added through rest call
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE2}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the entry added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE2}

Create bridge of already added bridge
    [Documentation]    This will add bridge to the config datastore
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE1}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE1}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE1}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology to verify the entry of existing bridge added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE1}

Delete bridge manually
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-br ${BRIDGE2}

Get Operational Topology to verify the bridge has been deleted manually
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE2}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Config Topology Still Contains Bridge
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE2}

Delete the Bridge through rest call
    [Documentation]    This request will delete the bridge node from the config data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE2}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    @{list}    Create List    ${BRIDGE2}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

*** Keywords ***
OVSDB Connection Manager Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

OVSDB Connection Manager Suite Teardown
    [Documentation]  Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment
    Delete All Sessions
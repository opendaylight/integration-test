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
${OVSDB_PORT}     6640
${BRIDGE}         ovsdb-csit-test-bridge
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${MININET}:${OVSDB_PORT}    ${MININET}    ${OVSDB_PORT}

*** Test Cases ***
Connecting an OVS instance to the controller
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager tcp:${CONTROLLER}:${OVSDB_PORT}

Get Operational Topology to verify the ovs instance is connected to the controller
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ovsdb:1

Get Config Topology
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb:1

Create bridge manually
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl add-br ${BRIDGE}

Get Operational Topology to verify the bridge has been added
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the manually added bridge is not added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should not Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE}

Create a Bridge through controller
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology to verify the bridge has been added through rest call
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the entry added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE}

Create bridge of already added bridge
    [Documentation]    This will add bridge to the config datastore
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology to verify the entry of existing bridge added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE}

Delete bridge manually
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-br ${BRIDGE}

Get Operational Topology to verify the bridge has been deleted manually
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the entry deleted from the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should not Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/${BRIDGE}

Delete the Bridge through rest call
    [Documentation]    This request will delete the bridge node from the config data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

*** Keywords ***
OVSDB Connection Manager Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

OVSDB Connection Manager Suite Teardown
    [Documentation]  Cleans up test environment, close existing sessions.
    SSHLibrary.Delete All Sessions
    Clean OVSDB Test Environment
*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${OVSDB_PORT}     6644
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:6644
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${MININET}:${OVSDB_PORT}    ${MININET}    ${OVSDB_PORT}    true    br-int

*** Test Cases ***
Connecting an OVS instance to the controller
    [Tags]    Southbound
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager tcp:${CONTROLLER}:6640

Get Operational Topology to verify the ovs instance is connected to the controller
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    [Tags]    Southbound
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}

Get Config Topology
    [Documentation]    This request will fetch the configuration topology from configuration data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/br-int

Create bridge manually
    [Tags]    Southbound
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl add-br br-s1

Get Operational Topology to verify the bridge has been added
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    [Tags]    Southbound
    @{list}    Create List    br-s1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the manually added bridge is not added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should not Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/br-s1

Create a Bridge through controller
    [Documentation]    This will create bridge on the specified OVSDB node.
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    br-s2
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-s2
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-s2    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology to verify the bridge has been added through rest call
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    [Tags]    Southbound
    @{list}    Create List    br-s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the entry added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/br-s2

Create bridge of already added bridge
    [Documentation]    This will add bridge to the config datastore
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    br-s1
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-s1
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-s1    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology to verify the entry of existing bridge added to the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/br-s1

Delete bridge manually
    [Tags]    Southbound
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-br br-s2

Get Operational Topology to verify the bridge has been deleted manually
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    [Tags]    Southbound
    @{list}    Create List    br-s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology to verify the entry deleted from the config datastore
    [Documentation]    This request will fetch the configuration topology from configuration data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should not Contain    ${resp.content}    ovsdb://${MININET}:${OVSDB_PORT}/bridge/br-s2

Delete the Bridge through rest call
    [Documentation]    This request will delete the bridge node from the config data store.
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-s1
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Delete the integration Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-int
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    [Tags]    Southbound
    @{list}    Create List    br-int    br-s1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

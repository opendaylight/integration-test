*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${OVSDB_PORT}     6634
${BRIDGE}         br01
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${MININET}:${OVSDB_PORT}    ${MININET}    ${OVSDB_PORT}    br-int

*** Test Cases ***
Make the OVS instance to listen for connection
    [Tags]    Southbound
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager ptcp:6634

Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${MININET}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    [Tags]    Southbound
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}

Create a Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ${BRIDGE}

Get Operational Topology with Bridge
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    [Tags]    Southbound
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Create Port and attach to a Bridge
    [Documentation]    This request will creates port/interface and attach it to the specific bridge
    [Tags]    Southbound
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    [Tags]    Southbound
    @{list}    Create List    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Port
    [Documentation]    This request will delete the port node from the bridge node and data store.
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Port
    [Documentation]    This request will fetch the operational topology after the Port is deleted
    [Tags]    Southbound
    @{list}    Create List    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    [Tags]    Southbound
    @{list}    Create List    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology with integration Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    br-int

Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology to make sure the connection has been deleted
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    [Tags]    Southbound
    @{list}    Create List    ovsdb://${MININET}:${OVSDB_PORT}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Configuration Topology to make sure the connection has been deleted
    [Documentation]    This request will fetch the configuration topology from the connected OVSDB nodes
    [Tags]    Southbound
    @{list}    Create List    ovsdb://${MININET}:${OVSDB_PORT}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${CONFIG_TOPO_API}    ${node_list}

Reconnect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${MININET}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology with Integration Bridge
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    [Tags]    Southbound
    @{list}    Create List    br-int
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Get Config Topology after reconnect
    [Documentation]    This will fetch the configuration topology from configuration data store after reconnect
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    br-int

Create integration Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    br-int
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-int    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete the integration Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2Fbr-int
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of integration Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    [Tags]    Southbound
    @{list}    Create List    br-int
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Again Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of OVSDB Node
    [Documentation]    This request will fetch the operational topology after the OVSDB node is deleted
    [Tags]    Southbound
    @{list}    Create List    ovsdb://${MININET}:${OVSDB_PORT}    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

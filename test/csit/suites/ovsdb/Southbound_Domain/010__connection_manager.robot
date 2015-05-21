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
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDB_PORT}
${FILE}           ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://${MININET}:${OVSDB_PORT}    ${MININET}    ${OVSDB_PORT}

*** Test Cases ***
Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${FILE}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${MININET}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology
    [Documentation]    This will fetch the configuration topology from configuration data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ${MININET}:${OVSDB_PORT}

Get Operational Topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    [Tags]    Southbound
    Wait Until Keyword Succeeds    6s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}

Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion
    [Documentation]    This request will fetch the operational topology after the OVSDB node is deleted
    [Tags]    Southbound
    Wait Until Keyword Succeeds    6s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${node_list}

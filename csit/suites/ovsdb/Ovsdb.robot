*** Settings ***
Library           RequestsLibrary
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../variables/Variables.robot

*** Variables ***
${SOUTHBOUND_NODE_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}

*** Keywords ***
Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Open Controller Karaf Console On Background
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    OVSDB.Log Config And Operational Topology

Suite Teardown
    [Arguments]    ${uris}=@{EMPTY}
    [Documentation]    Cleans up test environment, close existing sessions.
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    : FOR    ${uri}    IN    @{uris}
    \    RequestsLibrary.Delete Request    session    ${uri}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Config And Operational Topology
    RequestsLibrary.Delete All Sessions

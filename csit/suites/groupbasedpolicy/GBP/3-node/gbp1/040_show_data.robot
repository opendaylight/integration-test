*** Settings ***
Documentation     Deep inspection of HTTP traffic on asymmetric chain.
...               Nodes are located on different VMs.
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot

*** Variables ***

*** Testcases ***
Show GBPSFC1 Status
    [Documentation]    Shows flows and configuration of a switch for easier debugging.
    Start Connections
    Switch Connection    GBP1_CONNECTION
    Show Switch Status    sw1

Show GBPSFC2 Status
    [Documentation]    Shows flows and configuration of a switch for easier debugging.
    Switch Connection    GBP2_CONNECTION
    Show Switch Status    sw2

Show GBPSFC3 Status
    [Documentation]    Shows flows and configuration of a switch for easier debugging.
    Switch Connection    GBP3_CONNECTION
    Show Switch Status    sw3
    Close Connections

Read Tenants Confing From ODL
    [Documentation]    Logs ODL data store.
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
    ${resp}    RequestsLibrary.Get Request    session    ${GBP_TENANTS_API}
    Log    ${resp.content}

Read Tenants Operational From ODL
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_GBP_TENANTS_API}
    Log    ${resp.content}

Read Nodes Config From ODL
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}
    Log    ${resp.content}

Read Nodes Operational From ODL
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Log    ${resp.content}

Read Topology Config From ODL
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}

Read Topology Operational From ODL
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.content}

Read Endpoints From ODL
    ${resp}    RequestsLibrary.Get Request    session    ${GBP_ENDPOINTS_API}
    Log    ${resp.content}
    Delete All Sessions

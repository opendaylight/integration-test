*** Settings ***
Documentation     Test suite for AddressObservations in RESTCONF inventory
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${IP_1}           "10.0.0.1"
${IP_2}           "10.0.0.2"
${IP_3}           "10.0.0.3"

*** Test Cases ***
Check Stats for node 1
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow:1

Check Stats for node 2
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow:2

Check Stats for node 3
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow:3

Check No Host Is Present
    [Documentation]    Get the invnetory, should not contain any host address
    @{list}    Create List    ${IP_1}    ${IP_2}    ${IP_3}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_NODES_API}    ${list}

Ping All
    [Documentation]    Pingall, verify no packet loss
    Write    pingall
    ${result}    Read Until    mininet>
    Should Contain    ${result}    Results: 0% dropped

Check node 1 addresses
    [Documentation]    Get the address observations for node 1
    @{list}    Create List    ${IP_2}    ${IP_3}
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1    ${IP_1}    1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_NODES_API}/node/openflow:1    ${list}

Check node 2 addresses
    [Documentation]    Get the address observations for node 2
    @{list}    Create List    ${IP_1}    ${IP_3}
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:2    ${IP_2}    1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_NODES_API}/node/openflow:2    ${list}

Check node 3 addresses
    [Documentation]    Get the address observations for node 3
    @{list}    Create List    ${IP_1}    ${IP_2}
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:3    ${IP_3}    1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_NODES_API}/node/openflow:3    ${list}

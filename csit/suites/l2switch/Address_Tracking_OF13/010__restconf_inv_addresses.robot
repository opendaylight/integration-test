*** Settings ***
Documentation     Test suite for AddressObservations in RESTCONF inventory
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/openflowplugin/Variables.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${IP_1}           "10.0.0.1"
${IP_2}           "10.0.0.2"
${IP_3}           "10.0.0.3"

*** Test Cases ***
Check Stats for node 1
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow%3A1

Check Stats for node 2
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow%3A2

Check Stats for node 3
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow%3A3

Check No Host Is Present
    [Documentation]    Get the invnetory, should not contain any host address
    @{list}    Create List    ${IP_1}    ${IP_2}    ${IP_3}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${RFC8040_OPERATIONAL_NODES_API}    ${list}

Ping All
    [Documentation]    Pingall, verify no packet loss
    Wait Until Keyword Succeeds    10s    2s    Ping All Works Good

Check node 1 addresses
    [Documentation]    Get the address observations for node 1
    @{list}    Create List    ${IP_2}    ${IP_3}
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${RFC8040_NODES_API}/node=openflow%3A1?content=nonconfig    ${IP_1}    1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${RFC8040_NODES_API}/node=openflow%3A1?content=nonconfig    ${list}

Check node 2 addresses
    [Documentation]    Get the address observations for node 2
    @{list}    Create List    ${IP_1}    ${IP_3}
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${RFC8040_NODES_API}/node=openflow%3A2?content=nonconfig    ${IP_2}    1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${RFC8040_NODES_API}/node=openflow%3A2?content=nonconfig    ${list}

Check node 3 addresses
    [Documentation]    Get the address observations for node 3
    @{list}    Create List    ${IP_1}    ${IP_2}
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${RFC8040_NODES_API}/node=openflow%3A3?content=nonconfig    ${IP_3}    1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${RFC8040_NODES_API}/node=openflow%3A3?content=nonconfig    ${list}

*** Keywords ***
Ping All Works Good
    Write    pingall
    ${result}    Read Until    mininet>
    Should Contain    ${result}    Results: 0% dropped

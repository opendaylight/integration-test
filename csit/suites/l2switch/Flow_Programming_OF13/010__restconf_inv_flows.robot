*** Settings ***
Documentation     Test suite for FlowProgramming in RESTCONF inventory
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/openflowplugin/Variables.robot
Variables         ../../../variables/Variables.py

*** Variables ***

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

Check Flows
    [Documentation]    Check all flows are present
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${RFC8040_OPERATIONAL_NODES_API}    "output-node-connector"    21

Ping All Test
    [Documentation]    Ping all, verify no packet loss or duplicates
    Write    pingall
    ${result}    Read Until    mininet>
    Should Contain    ${result}    Results: 0% dropped

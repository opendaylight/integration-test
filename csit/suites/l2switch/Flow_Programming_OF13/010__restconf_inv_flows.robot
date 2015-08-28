*** Settings ***
Documentation     Test suite for FlowProgramming in RESTCONF inventory
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***

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

Check Flows
    [Documentation]    Check all flows are present
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    "output-node-connector"    21

Ping All Test
    [Documentation]    Ping all, verify no packet loss or duplicates
    Write    pingall
    ${result}    Read Until    mininet>
    Should Contain    ${result}    Results: 0% dropped

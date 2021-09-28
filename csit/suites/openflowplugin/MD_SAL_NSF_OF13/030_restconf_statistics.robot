*** Settings ***
Documentation     Test suite for RESTCONF statistics
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/openflowplugin/Variables.robot

*** Variables ***
@{node_list}      openflow:1    openflow:2    openflow:3

*** Test Cases ***
Get Stats for all nodes
    [Documentation]    Get the stats for all nodes
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${RFC8040_OPERATIONAL_NODES_API}    ${node_list}

Get Stats for node 1
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow%3A1

Get Stats for node 2
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow%3A2

Get Stats for node 3
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow%3A3

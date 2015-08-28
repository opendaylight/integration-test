*** Settings ***
Documentation     Test suite for RESTCONF statistics
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REST_CONTEXT}    /restconf/operational/opendaylight-inventory:nodes
@{node_list}      openflow:1    openflow:2    openflow:3

*** Test Cases ***
Get Stats for all nodes
    [Documentation]    Get the stats for all nodes
    Wait Until Keyword Succeeds    30s    2s    Ensure All Nodes Are In Response    ${REST_CONTEXT}    ${node_list}
Get Stats for node 1
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    60s    2s    Check Nodes Stats    openflow:1

Get Stats for node 2
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    60s    2s    Check Nodes Stats    openflow:2

Get Stats for node 3
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    60s    2s    Check Nodes Stats    openflow:3

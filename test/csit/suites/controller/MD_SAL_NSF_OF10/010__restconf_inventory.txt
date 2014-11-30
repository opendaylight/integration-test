*** Settings ***
Documentation     Test suite for RESTCONF inventory
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${REST_CONTEXT}    /restconf/operational/opendaylight-inventory:nodes
@{node_list}      openflow:1    openflow:2    openflow:3

*** Test Cases ***
Get list of nodes
    [Documentation]    Get the inventory
    Log    ${start}
    Wait Until Keyword Succeeds    30s    2s    Ensure All Nodes Are In Response    ${REST_CONTEXT}    ${node_list}

Get nodeconnector for a node 1
    [Documentation]    Get the inventory for a node
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/node/openflow:1
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    openflow:1:1
    Should Contain    ${resp.content}    openflow:1:2

Get nodeconnector for a node 2
    [Documentation]    Get the inventory for a node
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/node/openflow:2
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    openflow:2:1
    Should Contain    ${resp.content}    openflow:2:2
    Should Contain    ${resp.content}    openflow:2:3

Get nodeconnector for a node 3
    [Documentation]    Get the inventory for a node
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/node/openflow:3
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    openflow:3:1
    Should Contain    ${resp.content}    openflow:3:2
    Should Contain    ${resp.content}    openflow:3:3

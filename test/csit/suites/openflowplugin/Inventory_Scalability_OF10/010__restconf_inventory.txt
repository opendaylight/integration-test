*** Settings ***
Documentation     Test suite for RESTCONF inventory
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    /restconf/operational/opendaylight-inventory:nodes

*** Test Cases ***
Get list of nodes
    [Documentation]    Get the inventory
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Wait Until Keyword Succeeds    30s    2s    Check Every Nodes    ${numnodes}

Get nodeconnector for the root node
    [Documentation]    Get the inventory for the root node
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/node/openflow:1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    30s    2s    Check conn loop    ${TOPO_TREE_FANOUT}    1    ${resp.content}

Get nodeconnector for a node
    [Documentation]    Get the inventory for a node
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Wait Until Keyword Succeeds    30s    2s    Check Every Nodes Nodeconnector    ${numnodes}

Get Stats for a node
    [Documentation]    Get the stats for a node
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Wait Until Keyword Succeeds    120s    2s    Check Every Nodes Stats    ${numnodes}

*** Keywords ***
Check Every Nodes
    [Arguments]    ${numnodes}
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${IND}    IN RANGE    1    ${numnodes+1}
    \    Should Contain    ${resp.content}    openflow:${IND}

Check Every Nodes Stats
    [Arguments]    ${numnodes}
    : FOR    ${IND}    IN RANGE    1    ${numnodes+1}
    \    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/node/openflow:${IND}
    \    Log    ${resp.content}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    Should Contain    ${resp.content}    flow-capable-node-connector-statistics
    \    Should Contain    ${resp.content}    flow-table-statistics

Check Every Nodes Nodeconnector
    [Arguments]    ${numnodes}
    : FOR    ${IND}    IN RANGE    2    ${numnodes+1}
    \    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/node/openflow:${IND}
    \    Log    ${resp.content}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    Check conn loop    ${TOPO_TREE_FANOUT+1}    ${IND}    ${resp.content}

Check conn loop
    [Arguments]    ${arg}    ${outerind}    ${content}
    : FOR    ${var}    IN RANGE    1    ${arg+1}
    \    Should Contain    ${content}    openflow:${outerind}:${var}

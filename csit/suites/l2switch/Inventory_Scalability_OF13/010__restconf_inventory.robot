*** Settings ***
Documentation       Test suite for RESTCONF inventory

Library             Collections
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown      Delete All Sessions


*** Variables ***
${REST_CONTEXT}     /rests/data/opendaylight-inventory:nodes


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
    ${resp}    RequestsLibrary.GET On Session
    ...    session
    ...    url=${REST_CONTEXT}/node=openflow%3A1?content=nonconfig
    ...    expected_status=200
    Log    ${resp.content}
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
    ${resp}    RequestsLibrary.GET On Session
    ...    session
    ...    url=${REST_CONTEXT}?content=nonconfig
    ...    expected_status=200
    FOR    ${IND}    IN RANGE    1    ${numnodes+1}
        Should Contain    ${resp.content}    openflow:${IND}
    END

Check Every Nodes Stats
    [Arguments]    ${numnodes}
    FOR    ${IND}    IN RANGE    1    ${numnodes+1}
        ${resp}    RequestsLibrary.GET On Session
        ...    session
        ...    url=${REST_CONTEXT}/node=openflow%3A${IND}?content=nonconfig
        ...    expected_status=200
        Log    ${resp.content}
        Should Contain    ${resp.content}    flow-capable-node-connector-statistics
        Should Contain    ${resp.content}    flow-table-statistics
    END

Check Every Nodes Nodeconnector
    [Arguments]    ${numnodes}
    FOR    ${IND}    IN RANGE    2    ${numnodes+1}
        ${resp}    RequestsLibrary.GET On Session
        ...    session
        ...    url=${REST_CONTEXT}/node=openflow%3A${IND}?content=nonconfig
        ...    expected_status=200
        Log    ${resp.content}
        Check conn loop    ${TOPO_TREE_FANOUT+1}    ${IND}    ${resp.content}
    END

Check conn loop
    [Arguments]    ${arg}    ${outerind}    ${content}
    FOR    ${var}    IN RANGE    1    ${arg+1}
        Should Contain    ${content}    openflow:${outerind}:${var}
    END

*** Settings ***
Documentation     Test suite for RESTCONF inventory
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../variables/openflowplugin/Variables.robot

*** Variables ***

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
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A1?${RFC8040_OPERATIONAL_CONTENT}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    30s    2s    Check conn loop    ${TOPO_TREE_FANOUT}    1    ${resp.text}

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
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    FOR    ${IND}    IN RANGE    1    ${numnodes+1}
        Should Contain    ${resp.text}    openflow%3A${IND}
    END

Check Every Nodes Stats
    [Arguments]    ${numnodes}
    FOR    ${IND}    IN RANGE    1    ${numnodes+1}
        ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A${IND}?${RFC8040_OPERATIONAL_CONTENT}
        Log    ${resp.text}
        Should Be Equal As Strings    ${resp.status_code}    200
        Should Contain    ${resp.text}    flow-capable-node-connector-statistics
        Should Contain    ${resp.text}    flow-table-statistics
    END

Check Every Nodes Nodeconnector
    [Arguments]    ${numnodes}
    FOR    ${IND}    IN RANGE    2    ${numnodes+1}
        ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A1${IND}?${RFC8040_OPERATIONAL_CONTENT}
        Log    ${resp.text}
        Should Be Equal As Strings    ${resp.status_code}    200
        Check conn loop    ${TOPO_TREE_FANOUT+1}    ${IND}    ${resp.text}
    END

Check conn loop
    [Arguments]    ${arg}    ${outerind}    ${content}
    FOR    ${var}    IN RANGE    1    ${arg+1}
        Should Contain    ${content}    openflow%3A${outerind}:${var}
    END

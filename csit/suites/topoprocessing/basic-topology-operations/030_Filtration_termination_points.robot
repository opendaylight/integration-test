*** Settings ***
Documentation     Test suite to verify fitration operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Delete Overlay Topology
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/topoprocessing/TargetFields.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Test Cases ***
Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OVSDB_OFPORT}
    ${request}    Set Range Number Filter    ${request}    1115    1119
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6    tp:6:1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:1    tp:7:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OPENFLOW_NODE_CONNECTOR_PORT_NUMBER}
    ${request}    Set Range Number Filter    ${request}    2    4
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=5    tp-ref_count=5
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:3    tp:2:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3    tp:3:1    tp:3:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5    tp:5:1

Filtration Specific Number Network Topology Model
    [Documentation]    Test of specific number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    ${OVSDB_OFPORT}
    ${request}    Set Specific Number Filter    ${request}    1119
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=1    tp-ref_count=1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10

Filtration Specific Number Inventory Model
    [Documentation]    Test of specific number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    ${OPENFLOW_NODE_CONNECTOR_MAXIMUM_SPEED}
    ${request}    Set Specific Number Filter    ${request}    2
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3    tp:3:1    tp:3:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ${OVSDB_TP_NAME}
    ${request}    Set Specific String Filter    ${request}    portC
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=1    tp-ref_count=1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ${OPENFLOW_NODE_CONNECTOR_NAME}
    ${request}    Set Specific String Filter    ${request}    portB
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=2    tp-ref_count=2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5    tp:5:1

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ${OVSDB_TP_NAME}
    ${request}    Set Range String Filter    ${request}    portA    portC
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6    tp:6:1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10    tp:10:1

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ${OPENFLOW_NODE_CONNECTOR_NAME}
    ${request}    Set Range String Filter    ${request}    portA    portB
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:1    tp:2:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5    tp:5:1

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ${OVSDB_OFPORT}
    ${script}    Set Variable    if (node.getValue() > 1117 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:4    tp:4:1    tp:4:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:5    tp:5:1

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ${OPENFLOW_NODE_CONNECTOR_NAME}
    ${script}    Set Variable    if (node.getValue().indexOf("portB") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1    tp:1:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:2    tp:2:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5

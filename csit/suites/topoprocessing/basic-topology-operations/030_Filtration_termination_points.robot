*** Settings ***
Documentation     Test suite to verify fitration operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Teardown     Test Teardown    network-topology:network-topology/topology/topo:1
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Test Cases ***
Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ovsdb:ofport    network-topology-model
    ${request}    Set Range Number Filter    ${request}    1115    1119
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    3
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:1    tp:7:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6    tp:6:1

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    flow-node-inventory:port-number    opendaylight-inventory-model
    ${request}    Set Range Number Filter    ${request}    2    4
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    5
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    5
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5    tp:5:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3    tp:3:1    tp:3:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:3    tp:2:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1

Filtration Specific Number Network Topology Model
    [Documentation]    Test of specific number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    ovsdb:ofport    network-topology-model
    ${request}    Set Specific Number Filter    ${request}    1119
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    1
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6

Filtration Specific Number Inventory Model
    [Documentation]    Test of specific number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    flow-node-inventory:maximum-speed    opendaylight-inventory-model
    ${request}    Set Specific Number Filter    ${request}    2
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    3
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3    tp:3:1    tp:3:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ovsdb:name    network-topology-model
    ${request}    Set Specific String Filter    ${request}    portC
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    1
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    flow-node-inventory:name    opendaylight-inventory-model
    ${request}    Set Specific String Filter    ${request}    portB
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    2
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    2
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5    tp:5:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ovsdb:name    network-topology-model
    ${request}    Set Range String Filter    ${request}    portA    portC
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    3
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:10    tp:10:1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:9
    Check Filtered Termination Points in Node    ${resp.content}    bgp:8
    Check Filtered Termination Points in Node    ${resp.content}    bgp:7    tp:7:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:6    tp:6:1

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    flow-node-inventory:name    opendaylight-inventory-model
    ${request}    Set Range String Filter    ${request}    portA    portB
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    3
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5    tp:5:1
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:1    tp:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ovsdb:ofport    network-topology-model
    ${script}    Set Variable    if (node.getValue() > 1117 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    3
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:5    tp:5:1
    Check Filtered Termination Points in Node    ${resp.content}    bgp:4    tp:4:1    tp:4:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:3
    Check Filtered Termination Points in Node    ${resp.content}    bgp:2
    Check Filtered Termination Points in Node    ${resp.content}    bgp:1

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    flow-node-inventory:name    opendaylight-inventory-model
    ${script}    Set Variable    if (node.getValue().indexOf("portB") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <termination-point    3
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:5
    Check Filtered Termination Points in Node    ${resp.content}    of-node:4
    Check Filtered Termination Points in Node    ${resp.content}    of-node:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:2    tp:2:1    tp:3
    Check Filtered Termination Points in Node    ${resp.content}    of-node:1    tp:1:1

*** Keywords ***
Check Filtered Termination Points in Node
    [Arguments]    ${xml}    ${supp_node_id}    @{supp_tp_ids}
    ${node}    Get Element    ${xml}    xpath=.//node/supporting-node[node-ref='${supp_node_id}']/..
    ${node}    Element to String    ${node}
    ${supp_tp_count}    Get Length    ${supp_tp_ids}
    Should Contain X Times    ${node}    <supporting-node>    1
    Should Contain X Times    ${node}    <termination-point    ${supp_tp_count}
    Should Contain X Times    ${node}    <supporting-termination-point>    ${supp_tp_count}
    : FOR    ${supp_tp_id}    IN    @{supp_tp_ids}
    \    Element Text Should Be    ${node}    ${supp_tp_id}    xpath=.//termination-point/supporting-termination-point[tp-ref='${supp_tp_id}']/tp-ref

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
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ovsdb:ofport
    ${request}    Set Range Number Filter    ${request}    1115    1119
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:2</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:6']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:6/termination-point/tp:6:1</tp-ref>    1

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    flow-node-inventory:port-number
    ${request}    Set Range Number Filter    ${request}    2    4
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    5
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:3</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:2</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:2</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:1</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:5/termination-point/tp:5:1</tp-ref>    1

Filtration Specific Number Network Topology Model
    [Documentation]    Test of specific number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    ovsdb:ofport
    ${request}    Set Specific Number Filter    ${request}    1119
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:1</tp-ref>    1

Filtration Specific Number Inventory Model
    [Documentation]    Test of specific number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    flow-node-inventory:maximum-speed
    ${request}    Set Specific Number Filter    ${request}    2
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:2</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:2</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:1</tp-ref>    1

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ovsdb:name
    ${request}    Set Specific String Filter    ${request}    portC
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:2</tp-ref>    1

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    flow-node-inventory:name
    ${request}    Set Specific String Filter    ${request}    portB
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:1</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:5/termination-point/tp:5:1</tp-ref>    1

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ovsdb:name
    ${request}    Set Range String Filter    ${request}    portA    portC
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>    ${EMPTY}
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:6']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:6/termination-point/tp:6:1</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:2</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:10/termination-point/tp:10:1</tp-ref>    1

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    flow-node-inventory:name
    ${request}    Set Range String Filter    ${request}    portA    portB
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:3</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:5/termination-point/tp:5:1</tp-ref>    1

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ovsdb:ofport
    ${script}    Set Variable    if (node.getValue() > 1117 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:4/termination-point/tp:4:2</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:4/termination-point/tp:4:1</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:5/termination-point/tp:5:1</tp-ref>    1

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    flow-node-inventory:name
    ${script}    Set Variable    if (node.getValue().indexOf("portB") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:3</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:2</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:1/termination-point/tp:1:1</tp-ref>    1

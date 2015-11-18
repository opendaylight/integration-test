*** Settings ***
Documentation     Test suite to verify fitration operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       KeywordsAndVariables.Setup Environment
Suite Teardown    KeywordsAndVariables.Clean Environment
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/topoprocessing/Topologies.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ./KeywordsAndVariables.robot

*** Test Cases ***
Filtration IPV4 Network Topology Model
    [Documentation]    Test of ipv4 type of filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address
    ${request}    KeywordsAndVariables.Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    4
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration IPV4 Inventory Model
    [Documentation]    Test of ipv4 type of filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address
    ${request}    KeywordsAndVariables.Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ovsdb:ofport
    ${request}    KeywordsAndVariables.Set Range Number Filter    ${request}    1115    1119
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    flow-node-inventory:port-number
    ${request}    KeywordsAndVariables.Set Range Number Filter    ${request}    2    4
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Specific Number Network Topology Model
    [Documentation]    Test of specific number type of filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    ovsdb:ofport
    ${request}    KeywordsAndVariables.Set Specific Number Filter    ${request}    1119
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Specific Number Inventory Model
    [Documentation]    Test of specific number type of filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    flow-node-inventory:port-number
    ${request}    KeywordsAndVariables.Set Specific Number Filter    ${request}    1
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ovsdb:name
    ${request}    KeywordsAndVariables.Set Specific String Filter    ${request}    portC
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    flow-node-inventory:name
    ${request}    KeywordsAndVariables.Set Specific String Filter    ${request}    portB
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ovsdb:name
    ${request}    KeywordsAndVariables.Set Range String Filter    ${request}    portA    portC
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:6']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_RANGE_STRING}    flow-node-inventory:name
    ${request}    KeywordsAndVariables.Set Range String Filter    ${request}    portA    portB
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration IPV6 Network Topology Model
    [Documentation]    Test of ipv6 type of filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:3
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV6}    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address
    ${request}    KeywordsAndVariables.Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:101/120
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:11']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration IPV6 Inventory Model
    [Documentation]    Test of ipv6 type of filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:2
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV6}    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address
    ${request}    KeywordsAndVariables.Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:201/120
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.1") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    KeywordsAndVariables.Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.2") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    KeywordsAndVariables.Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

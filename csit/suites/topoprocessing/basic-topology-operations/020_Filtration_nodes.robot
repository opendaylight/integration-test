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
Filtration IPV4 Network Topology Model
    [Documentation]    Test of ipv4 type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-ref>bgp:1</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    3
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:3</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:2</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:3</tp-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:2</node-ref>    1

Filtration IPV4 Inventory Model
    [Documentation]    Test of ipv4 type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    flow-node-inventory:ip-address
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    1    4
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1

Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ovsdb:ovs-version
    ${request}    Set Range Number Filter    ${request}    20    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    7    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    5
    #node bgp:7
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:2</tp-ref>    1
    #node bgp:8
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:8']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:8/termination-point/tp:8:1</tp-ref>    1
    #node bgp:9
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:9']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:9/termination-point/tp:9:1</tp-ref>    1
    #node bgp:10
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:10/termination-point/tp:10:1</tp-ref>    1

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    flow-node-inventory:serial-number
    ${request}    Set Range Number Filter    ${request}    20    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    8    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1

Filtration Specific Number Network Topology Model
    [Documentation]    Test of specific number type of filtration operation on Network Topology model
    Pass Execution    Test is being passed due to incorrect target field. Test will be included in execution when corrected.
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    ovsdb:ovs-version
    ${request}    Set Specific Number Filter    ${request}    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-ref>bgp:9</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:10</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    2
    Should Contain    ${resp.content}    <tp-id>tp:9:1</tp-id>
    Should Contain    ${resp.content}    <tp-id>tp:10:1</tp-id>

Filtration Specific Number Inventory Model
    [Documentation]    Test of specific number type of filtration operation on Inventory model
    Pass Execution    Test is being passed due to incorrect target field. Test will be included in execution when corrected.
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_NUMBER}    flow-node-inventory:serial-number
    ${request}    Set Specific Number Filter    ${request}    21
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-ref>of-node:8</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:9</node-ref>    1

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ovsdb:ovs-version
    ${request}    Set Specific String Filter    ${request}    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>    ${EMPTY}
    Should Contain X Times    ${resp.content}    <node-ref>bgp:9</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:10</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    2
    #node bgp:9
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:9']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:9/termination-point/tp:9:1</tp-ref>    1
    #node bgp:10
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:10/termination-point/tp:10:1</tp-ref>    1

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    flow-node-inventory:serial-number
    ${request}    Set Specific String Filter    ${request}    21
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-ref>of-node:8</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:9</node-ref>    1

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ovsdb:ovs-version
    ${request}    Set Range String Filter    ${request}    20    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    7    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    5
    #node bgp:7
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:7']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:2</tp-ref>    1
    #node bgp:8
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:8']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:8/termination-point/tp:8:1</tp-ref>    1
    #node bgp:9
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:9']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:9/termination-point/tp:9:1</tp-ref>    1
    #node bgp:10
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:2/node/bgp:10/termination-point/tp:10:1</tp-ref>    1

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    flow-node-inventory:serial-number
    ${request}    Set Range String Filter    ${request}    20    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    8    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1

Filtration IPV6 Network Topology Model
    [Documentation]    Test of ipv6 type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_IPV6}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv6
    ${request}    Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:101/120
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-ref>bgp:11</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:12</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    1
    #node bgp:11
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:11']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:3/node/bgp:11/termination-point/tp:11:1</tp-ref>    1
    #node bgp:12
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:12']/..
    ${node}    Element to String    ${node}
    Should Not Contain    ${node}    <tp-ref>

Filtration IPV6 Inventory Model
    [Documentation]    Test of ipv6 type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_IPV6}    flow-node-inventory:ip-address
    ${request}    Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:201/120
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-ref>of-node:12</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:14</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:15</node-ref>    1

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.1") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    3    6
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    5
    #node bgp:3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:3/termination-point/tp:3:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:3/termination-point/tp:3:2</tp-ref>    1
    #node bgp:4
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:4/termination-point/tp:4:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:4/termination-point/tp:4:2</tp-ref>    1
    #node bgp:5
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:5/termination-point/tp:5:1</tp-ref>    1

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    flow-node-inventory:ip-address
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.2") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    1    4
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1

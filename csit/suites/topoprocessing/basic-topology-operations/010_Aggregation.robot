*** Settings ***
Documentation     Test suite to verify unification operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIG_API to OPERATIONAL_API.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Suite setup also install features required for tested models, clear karaf logs for further synchronization. Tests themselves send configurational
...               xmls and verify output. Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Teardown     Aggregation Test Teardown
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Test Cases ***
Unification Node
    [Documentation]    Test unification operation on Network Topology model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:1
    ...    network-topo:2
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    9
    : FOR    ${index}    IN RANGE    1    9
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:10</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:5</node-ref>    1

Unification Node Inventory
    [Documentation]    Test unification operation on inventory model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:1
    ...    openflow-topo:2
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    8
    : FOR    ${index}    IN RANGE    1    10
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:6</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:1</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:10</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:4</node-ref>    1

Unification Scripting Node
    [Documentation]    Test unification operation on Network Topology model using scripting
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:1
    ...    network-topo:2
    ${request}    Insert Scripting into Request    ${request}    javascript    if (originalItem.getLeafNode().getValue().indexOf("192.168.1.1") > -1 && newItem.getLeafNode().getValue().indexOf("192.168.1.3") > -1 || originalItem.getLeafNode().getValue().indexOf("192.168.1.3") > -1 && newItem.getLeafNode().getValue().indexOf("192.168.1.1") > -1) {aggregable.setResult(true);} else { aggregable.setResult(false);}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    9
    : FOR    ${index}    IN RANGE    1    10
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:1</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:6</node-ref>    1

Unification Scripting Node Inventory
    [Documentation]    Test unification operation on inventory model using scripting
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:1
    ...    openflow-topo:2
    ${request}    Insert Scripting into Request    ${request}    javascript    if (originalItem.getLeafNode().getValue().indexOf("192.168.1.2") > -1 && newItem.getLeafNode().getValue().indexOf("192.168.1.4") > -1 || originalItem.getLeafNode().getValue().indexOf("192.168.1.4") > -1 && newItem.getLeafNode().getValue().indexOf("192.168.1.2") > -1) {aggregable.setResult(true);} else { aggregable.setResult(false);}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    9
    : FOR    ${index}    IN RANGE    1    10
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:2</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:8</node-ref>    1

Unification Node Inside
    [Documentation]    Test of unification type of aggregation inside on nodes on Network Topology model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:1
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    4
    ${response_xml}    Parse XML    ${resp.content}
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='bgp:3']/..
    ${node}    Element To String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <supporting-node><node-ref>bgp:3</node-ref>
    Should Contain    ${node}    <supporting-node><node-ref>bgp:4</node-ref>

Unification Node Inside Inventory
    [Documentation]    Test of unification type of aggregation inside on nodes on Inventory model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:2
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    4
    ${response_xml}    Parse XML    ${resp.content}
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='of-node:7']/..
    ${node}    Element To String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <supporting-node><node-ref>of-node:7</node-ref>
    Should Contain    ${node}    <supporting-node><node-ref>of-node:9</node-ref>

Unification Termination Point Inside
    [Documentation]    Test aggregate inside operation on termination points
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    termination-point    ovsdb:ofport    network-topo:1
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    6
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Run Keywords    Aggregation Test Teardown
    ...    AND    Report_Failure_Due_To_Bug    4750

Unification Termination Point Inside Inventory
    [Documentation]    Test aggregate inside operation on termination points
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    termination-point    flow-node-inventory:port-number    openflow-topo:1
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${response_xml}    <termination-point>    8
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    3
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='of-node:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='of-node:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Run Keywords    Aggregation Test Teardown
    ...    AND    Report_Failure_Due_To_Bug    4674

*** Keywords ***
Aggregation Test Teardown
    Test Teardown    network-topology:network-topology/topology/topo:1
    Report_Failure_Due_To_Bug    4673

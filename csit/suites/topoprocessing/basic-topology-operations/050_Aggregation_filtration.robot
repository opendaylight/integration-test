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
Unification Filtration Node Inside Network Topology model
    [Documentation]    Test unification filtration inside operation on Network Topology model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain    ${resp.content}    <node-ref>bgp:    3
    : FOR    ${index}    IN RANGE    18    21
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:18']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <node-ref>bgp:18</node-ref>
    Should Contain    ${node}    <node-ref>bgp:20</node-ref>

Unification Filtration Node Inside Inventory model
    [Documentation]    Test unification filtration inside operation on Inventory model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    flow-node-inventory:ip-address    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain    ${resp.content}    <node-ref>of-node:    4
    : FOR    ${index}    IN RANGE    17    21
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:17']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    3
    Should Contain    ${node}    <node-ref>of-node:17</node-ref>
    Should Contain    ${node}    <node-ref>of-node:19</node-ref>
    Should Contain    ${node}    <node-ref>of-node:20</node-ref>

Unification Filtration Termination Point Inside Network Topology model
    [Documentation]    Test unification filtration inside operation on Network Topology model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    network-topology-model    termination-point    ovsdb:name    network-topo:5
    ${request}    Insert Filter With ID    ${request}    ${FILTER_SPECIFIC_STRING}    ovsdb:name    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set Specific String Filter    ${request}    portA
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:21']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>    3
    Should Contain    ${node}    <tp-ref>/network-topology:network-topology/topology/network-topo:5/node/bgp:21/termination-point/tp:21:2</tp-ref>
    Should Contain    ${node}    <tp-ref>/network-topology:network-topology/topology/network-topo:5/node/bgp:21/termination-point/tp:21:1</tp-ref>
    Should Contain    ${node}    <tp-ref>/network-topology:network-topology/topology/network-topo:5/node/bgp:21/termination-point/tp:21:3</tp-ref>
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:22']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>    1
    Should Contain    ${node}    <tp-ref>/network-topology:network-topology/topology/network-topo:5/node/bgp:22/termination-point/tp:22:1</tp-ref>
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:24']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>    2
    Should Contain    ${node}    <tp-ref>/network-topology:network-topology/topology/network-topo:5/node/bgp:24/termination-point/tp:24:1</tp-ref>
    Should Contain    ${node}    <tp-ref>/network-topology:network-topology/topology/network-topo:5/node/bgp:24/termination-point/tp:24:2</tp-ref>

Unification Filtration Node Network Topology model
    [Documentation]    Test unification filtration operation on Network Topology model
    ${target_field}    Set Variable    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Prepare Unification Filtration Topology Request    ${UNIFICATION_FILTRATION_NT}    network-topology-model    node    ${target_field}    network-topo:4
    ...    ${target_field}    network-topo:1
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Insert Apply Filters    ${request}    2    1
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node>    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain X Times    ${node}    <node-ref>bgp:1</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:16</node-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:3</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:2</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:1</tp-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain X Times    ${node}    <node-ref>bgp:2</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:17</node-ref>    1

Unification Filtration Node Inventory model
    [Documentation]    Test unification filtration operation on Inventory model
    ${request}    Prepare Unification Filtration Topology Request    ${UNIFICATION_FILTRATION_NT}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:4
    ...    flow-node-inventory:ip-address    openflow-topo:6
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    flow-node-inventory:ip-address    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Insert Apply Filters    ${request}    2    1
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node>    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:26']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:26</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:16</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:28']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:28</node-ref>    1

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
Unification Filtration Node Inside Network Topology model
    [Documentation]    Test unification filtration inside operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address    network-topo:4
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV4}    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address
    ${request}    KeywordsAndVariables.Set IPV4 Filter    ${request}    192.168.2.1/24
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    2
    Should Contain X Times    ${resp.content}    <node-ref>pcep:18</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:19</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:20</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:18']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <node-ref>pcep:18</node-ref>
    Should Contain    ${node}    <node-ref>pcep:20</node-ref>
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Unification Filtration Node Inside Inventory model
    [Documentation]    Test unification filtration inside operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:4
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV4}    flow-node-inventory:ip-address
    ${request}    KeywordsAndVariables.Set IPV4 Filter    ${request}    192.168.2.1/24
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    2
    Should Contain X Times    ${resp.content}    <node-ref>of-node:17</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:18</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:19</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:20</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:17']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    3
    Should Contain    ${node}    <node-ref>of-node:17</node-ref>
    Should Contain    ${node}    <node-ref>of-node:19</node-ref>
    Should Contain    ${node}    <node-ref>of-node:20</node-ref>
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Unification Filtration Termination Point Inside Network Topology model
    [Documentation]    Test unification filtration inside operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    network-topology-model    termination-point    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address    network-topo:5
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-termination-point-attributes/l3-unicast-igp-topology:ip-address
    ${request}    KeywordsAndVariables.Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    4
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:21']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:22']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:24']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Unification Filtration Node Network Topology model
    [Documentation]    Test unification filtration operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT}    network-topology-model    node    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address    network-topo:4
    ${request}    Prepare Unification Filtration Topology Request    ${request}    network-topology-model    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address    network-topo:1
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV4}    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address
    ${request}    KeywordsAndVariables.Set IPV4 Filter    ${request}    192.168.2.1/24
    Log    ${request}
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <node-ref>pcep:18</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:19</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:20</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:1</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:2</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:3</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:4</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:5</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:18']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    3
    Should Contain    ${node}    <node-ref>pcep:18</node-ref>
    Should Contain    ${node}    <node-ref>pcep:20</node-ref>
    Should Contain    ${node}    <node-ref>pcep:3</node-ref>
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:19']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <node-ref>pcep:19</node-ref>
    Should Contain    ${node}    <node-ref>pcep:4</node-ref>
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Unification Filtration Node Inventory model
    [Documentation]    Test unification filtration operation on Inventory model
    ${request}    KeywordsAndVariables.Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:4
    ${request}    Prepare Unification Filtration Topology Request    ${request}    opendaylight-inventory-model    flow-node-inventory:ip-address    openflow-topo:6
    ${request}    KeywordsAndVariables.Insert Filter    ${request}    ${FILTER_IPV4}    flow-node-inventory:ip-address
    ${request}    KeywordsAndVariables.Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Basic Filtration    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <node-ref>of-node:6</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:7</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:8</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:9</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:10</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:16</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:6']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <node-ref>of-node:6</node-ref>
    Should Contain    ${node}    <node-ref>of-node:16</node-ref>
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

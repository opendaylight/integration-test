*** Settings ***
Documentation     Test suite to verify unification operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Suit setup also install features required for tested models, clear karaf logs for further synchronization. Tests themselves send configurational
...               xmls and verify output. Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
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
Unification Node
    [Documentation]    Test unification operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address    network-topo:1
    ...    network-topo:2
    ${resp}    Basic Aggregation    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    9
    Should Contain X Times    ${resp.content}    <node-ref>pcep:1</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:2</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:3</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:4</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:5</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:6</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:7</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:8</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>pcep:9</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='pcep:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>pcep:10</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>pcep:5</node-ref>    1
    [Teardown]    Test Teardown

Unification Node Inventory
    [Documentation]    Test unification operation on Network Topology model
    ${request}    KeywordsAndVariables.Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:1
    ...    openflow-topo:2
    ${resp}    Basic Aggregation    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    8
    Should Contain X Times    ${resp.content}    <node-ref>of-node:1</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:2</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:3</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:4</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:5</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:6</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:7</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:8</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:9</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>of-node:10</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:6</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:1</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:10</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:4</node-ref>    1
    [Teardown]    Test Teardown

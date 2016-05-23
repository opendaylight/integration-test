*** Settings ***
Documentation     Test suite to verify unification operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIG_API to OPERATIONAL_API.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Suite setup also install features required for tested models, clear karaf logs for further synchronization. Tests themselves send configurational
...               xmls and verify output. Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
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
Unification Node Update
    [Documentation]    Test processing of updates using unification operation on Network Topology model
    #Create the original topology
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Target Field    ${request}    1    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    8

    #Update a node, expecting a unification of two nodes into one
    ${node}    Create Isis Node    bgp:1    192.168.1.2
    Basic Request Put    ${node}    network-topology:network-topology/topology/network-topo:1/node/bgp:1
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    7
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:2</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:1</node-ref>    1

    #Update a unified node, expecting creation of a new overlay node
    ${node}    Create Isis Node    bgp:3    192.168.3.1
    Basic Request Put    ${node}    network-topology:network-topology/topology/network-topo:1/node/bgp:3
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    8
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1

Unification Node Inventory
    [Documentation]    Test processing of updates using unification operation on Inventory model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${request}    Insert Target Field    ${request}    1    flow-node-inventory:ip-address    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    7

    #Update a node, expecting unification of two nodes into one
    ${node}    Create Openflow Node    openflow:2    192.168.1.1

    Basic Request Put    ${node}    opendaylight-inventory:nodes/node/openflow:2
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    6
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:6</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:1</node-ref>    1

    #Update a unified node, expecting creation of a new overlay node
    ${node}    Create Openflow Node    openflow:4    192.168.3.1
    Basic Request Put    ${node}    opendaylight-inventory:nodes/node/openflow:4
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    7
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
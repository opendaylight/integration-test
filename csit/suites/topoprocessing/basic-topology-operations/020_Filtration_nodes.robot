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
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topology-model
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    3    bgp:1    bgp:2

Filtration IPV4 Inventory Model
    [Documentation]    Test of ipv4 type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    flow-node-inventory:ip-address    opendaylight-inventory-model
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Nodes in Network    ${resp.content}    topo:1    8    of-node:1    of-node:2    of-node:3

Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ovsdb:ovs-version    network-topology-model
    ${request}    Set Range Number Filter    ${request}    20    25
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    5    bgp:7    bgp:8    bgp:9
    ...    bgp:10

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    flow-node-inventory:serial-number    opendaylight-inventory-model
    ${request}    Set Range Number Filter    ${request}    20    25
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    0    of-node:8    of-node:9    of-node:10

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ovsdb:ovs-version    network-topology-model
    ${request}    Set Specific String Filter    ${request}    25
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    2    bgp:9    bgp:10

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    flow-node-inventory:serial-number    opendaylight-inventory-model
    ${request}    Set Specific String Filter    ${request}    21
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    0    of-node:8    of-node:9

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ovsdb:ovs-version    network-topology-model
    ${request}    Set Range String Filter    ${request}    20    25
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    5    bgp:7    bgp:8    bgp:9
    ...    bgp:10

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    flow-node-inventory:serial-number    opendaylight-inventory-model
    ${request}    Set Range String Filter    ${request}    20    25
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    0    of-node:8    of-node:9    of-node:10

Filtration IPV6 Network Topology Model
    [Documentation]    Test of ipv6 type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    network-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_IPV6}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv6    network-topology-model
    ${request}    Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:101/120
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    1    bgp:11    bgp:12

Filtration IPV6 Inventory Model
    [Documentation]    Test of ipv6 type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_IPV6}    flow-node-inventory:ip-address    opendaylight-inventory-model
    ${request}    Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:201/120
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    0    of-node:12    of-node:14    of-node:15

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topology-model
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.1") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    5    bgp:3    bgp:4    bgp:5

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    node    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    flow-node-inventory:ip-address    opendaylight-inventory-model
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.2") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Check Filtered Nodes in Network    ${resp.content}    topo:1    8    of-node:1    of-node:2    of-node:3

*** Keywords ***
Check Filtered Nodes in Network
    [Arguments]    ${xml}    ${network_id}    ${tp_count}    @{node_ids}
    ${node_count}    Get Length    ${node_ids}
    Should Contain X Times    ${xml}    <network-id>${network_id}</network-id>    1
    Should Contain X Times    ${xml}    <node>    ${node_count}
    Should Contain X Times    ${xml}    <supporting-node>    ${node_count}
    Should Contain X Times    ${xml}    <termination-point    ${tp_count}
    Should Contain X Times    ${xml}    <supporting-termination-point>    ${tp_count}
    : FOR    ${node_id}    IN    @{node_ids}
    \    Element Text Should Be    ${xml}    ${node_id}    xpath=.//node/supporting-node[node-ref='${node_id}']/node-ref

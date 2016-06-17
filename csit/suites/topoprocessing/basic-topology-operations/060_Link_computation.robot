*** Settings ***
Documentation     Test suite to verify link computation operation on different models.
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
Link Computation Aggregation Inside
    [Documentation]    Test of link computation with unification inside on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    ${model}    node    network-topo:6
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <link-id>    4
    ${overlay_node_id_28_29}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:28    bgp:29
    ${overlay_node_id_26}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:26
    ${overlay_node_id_30}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:30
    ${overlay_node_id_27}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:27
    ${topology_id}    Set Variable    network-topo:6
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:26:28    ${overlay_node_id_26}    ${overlay_node_id_28_29}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:28:29    ${overlay_node_id_28_29}    ${overlay_node_id_28_29}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:29:30-1    ${overlay_node_id_28_29}    ${overlay_node_id_30}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:29:30-2    ${overlay_node_id_28_29}    ${overlay_node_id_30}

Link Computation Filtration
    [Documentation]    Test of link computation with filtration on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    node    network-topo:6
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/32
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <link-id>    1
    ${overlay_node_id_28}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:28
    ${overlay_node_id_29}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:29
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    network-topo:6    link:28:29    ${overlay_node_id_28}    ${overlay_node_id_29}

Link Computation Aggregation Filtration
    [Documentation]    Test of link computation with aggregation filtration on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${target_field}    Set Variable    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Prepare Unification Filtration Topology Request    ${UNIFICATION_FILTRATION_NT}    ${model}    node    ${target_field}    network-topo:6
    ...    ${target_field}    network-topo:1
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Insert Apply Filters    ${request}    2    1
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${request}    Insert Link Computation    ${request}    ${LINK_COMPUTATION}    n:network-topology-model    network-topo:6    network-topo:1
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <link>    2
    ${overlay_node_id_1_26}    Check Aggregated Node in Topology    ${model}    ${resp.content}    3    bgp:26    bgp:1
    ${overlay_node_id_2_27}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:27    bgp:2
    ${topology_id}    Set Variable    network-topo:1
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:1:2-1    ${overlay_node_id_1_26}    ${overlay_node_id_2_27}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:1:2-2    ${overlay_node_id_1_26}    ${overlay_node_id_2_27}

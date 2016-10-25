*** Settings ***
Documentation     Test suite to verify link computation operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Delete Overlay Topology
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/topoprocessing/TargetFields.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Test Cases ***
Link Computation Aggregation Inside
    [Documentation]    Test of link computation with unification inside on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    ${model}    node    network-topo:6
    ${request}    Insert Target Field    ${request}    0    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=5
    ...    node-ref_count=5    link_count=4    link-ref_count=4
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
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/32
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=2
    ...    node-ref_count=2    link_count=1    link-ref_count=1
    ${overlay_node_id_28}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:28
    ${overlay_node_id_29}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:29
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    network-topo:6    link:28:29    ${overlay_node_id_28}    ${overlay_node_id_29}

Link Computation Aggregation Filtration
    [Documentation]    Test of link computation with aggregation filtration on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${target_field}    Set Variable    ${ISIS_NODE_TE_ROUTER_ID_IPV4}
    ${request}    Prepare Unification Filtration Topology Request    ${UNIFICATION_FILTRATION_NT}    ${model}    node    ${target_field}    network-topo:6
    ...    ${target_field}    network-topo:1
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Insert Apply Filters    ${request}    2    1
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${request}    Insert Link Computation    ${request}    ${LINK_COMPUTATION}    n:network-topology-model    network-topo:6    network-topo:1
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=4
    ...    node-ref_count=4    link_count=2    link-ref_count=2
    ${overlay_node_id_1_26}    Check Aggregated Node in Topology    ${model}    ${resp.content}    3    bgp:26    bgp:1
    ${overlay_node_id_2_27}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:27    bgp:2
    ${topology_id}    Set Variable    network-topo:1
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:1:2-1    ${overlay_node_id_1_26}    ${overlay_node_id_2_27}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topology_id}    link:1:2-2    ${overlay_node_id_1_26}    ${overlay_node_id_2_27}

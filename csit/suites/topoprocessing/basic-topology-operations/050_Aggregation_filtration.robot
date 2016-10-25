*** Settings ***
Documentation     Test suite to verify fitration operation on different models.
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
Unification Filtration Node Inside Network Topology model
    [Documentation]    Test unification filtration inside operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    ${model}    node    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    network-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:18    bgp:20
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:19

Unification Filtration Node Inside Inventory model
    [Documentation]    Test unification filtration inside operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    ${model}    node    ${OPENFLOW_NODE_IP_ADDRESS}    openflow-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${OPENFLOW_NODE_IP_ADDRESS}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=4
    ...    node-ref_count=4    tp_count=0    tp-ref_count=0
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    of-node:18
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    of-node:17    of-node:19    of-node:20

Unification Filtration Termination Point Inside Network Topology model
    [Documentation]    Test unification filtration inside operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    ${model}    termination-point    ${OVSDB_TP_NAME}    network-topo:5
    ${request}    Insert Filter With ID    ${request}    ${FILTER_SPECIFIC_STRING}    ${OVSDB_TP_NAME}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set Specific String Filter    ${request}    portA
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=6
    ${topology_id}    Set Variable    network-topo:5
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:21    tp:21:1    tp:21:1
    ...    tp:21:2    tp:21:3
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:24    tp:24:1    tp:24:1
    ...    tp:24:2
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:22    tp:22:1    tp:22:1

Unification Filtration Node Network Topology model
    [Documentation]    Test unification filtration operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${target_field}    Set Variable    ${ISIS_NODE_TE_ROUTER_ID_IPV4}
    ${request}    Prepare Unification Filtration Topology Request    ${UNIFICATION_FILTRATION_NT}    ${model}    node    ${target_field}    network-topo:4
    ...    ${target_field}    network-topo:1
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Insert Apply Filters    ${request}    2    1
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=4
    ...    node-ref_count=4    tp_count=3    tp-ref_count=3
    Check Aggregated Node in Topology    ${model}    ${resp.content}    3    bgp:1    bgp:16
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:2    bgp:17

Unification Filtration Node Inventory model
    [Documentation]    Test unification filtration operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    ${request}    Prepare Unification Filtration Topology Request    ${UNIFICATION_FILTRATION_NT}    ${model}    node    ${OPENFLOW_NODE_IP_ADDRESS}    openflow-topo:4
    ...    ${OPENFLOW_NODE_IP_ADDRESS}    openflow-topo:6
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${OPENFLOW_NODE_IP_ADDRESS}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Insert Apply Filters    ${request}    2    1
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    of-node:28
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    of-node:16    of-node:26

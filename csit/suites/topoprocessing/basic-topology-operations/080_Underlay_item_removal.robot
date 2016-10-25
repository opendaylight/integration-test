*** Settings ***
Documentation     Test suite to verify processing of removal requests on different models.
...               Before tests start, configurational files have to be rewriten to change listeners registration datastore type from CONFIG_API to OPERATIONAL_API.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Suite setup also installs features required for tested models and clears karaf logs for further synchronization. Tests themselves send configurational
...               xmls and verify output. Topology-id on the end of each url must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Refresh Underlay Topologies And Delete Overlay Topology
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
Unification Node Removal NT
    [Documentation]    Test processing of node removal using unification operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    #Create the original topology
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    ${request}    Insert Target Field    ${request}    1    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=8    supporting-node_count=10
    ...    node-ref_count=10
    #Remove an underlay aggregated node, preserving the overlay node
    Delete Underlay Node    network-topo:1    bgp:3
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=8    supporting-node_count=9
    ...    node-ref_count=9
    Check Aggregated Node in Topology    ${model}    ${resp.content}    2    bgp:4
    #Remove an underlay aggregated node, expecting removal of the overlay node
    Delete Underlay Node    network-topo:1    bgp:4
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=7    supporting-node_count=8
    ...    node-ref_count=8

Unification Node Removal Inventory
    [Documentation]    Test processing of node removal using unification operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    #Create the original topology
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    ${model}    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    ${OPENFLOW_NODE_IP_ADDRESS}    0
    ${request}    Insert Target Field    ${request}    1    ${OPENFLOW_NODE_IP_ADDRESS}    0
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=7    supporting-node_count=10
    ...    node-ref_count=10
    #Remove an underlay aggregated node, preserving the overlay node
    Delete Underlay Node    openflow-topo:2    of-node:6
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=7    supporting-node_count=9
    ...    node-ref_count=9
    Check Aggregated Node in Topology    ${model}    ${resp.content}    2    of-node:1
    #Remove an underlay aggregated node, expecting removal of the overlay node
    Delete Underlay Node    openflow-topo:1    of-node:1
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=6    supporting-node_count=8
    ...    node-ref_count=8

Filtration Range Number Node Removal NT
    [Documentation]    Test processing of node removal using filtration operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    #Create the original topology
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OVSDB_OVS_VERSION}
    ${request}    Set Range Number Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=4
    ...    node-ref_count=4    tp_count=5    tp-ref_count=5
    #Remove an underlay filtered node, expecting removal of the overlay node
    Delete Underlay Node    network-topo:2    bgp:7
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=3    tp-ref_count=3

Filtration Range Number Node Removal Inventory
    [Documentation]    Test processing of node removal using filtration operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    #Create the original topology
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OPENFLOW_NODE_SERIAL_NUMBER}
    ${request}    Set Range Number Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    #Remove an underlay filtered node, expecting removal of the overlay node
    Delete Underlay Node    openflow-topo:2    of-node:8
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=2
    ...    node-ref_count=2    tp_count=0    tp-ref_count=0

Filtration Range Number Termination Point Removal NT
    [Documentation]    Test processing of termination point removal using filtration operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    #Create the original topology
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OVSDB_OFPORT}
    ${request}    Set Range Number Filter    ${request}    1115    1119
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    #Remove an underlay filtered termination point
    Delete Underlay Termination Point    network-topo:2    bgp:7    tp:7:2
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=2    tp-ref_count=2
    #Remove an underlay filtered termination point
    Delete Underlay Termination Point    network-topo:2    bgp:7    tp:7:1
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=1    tp-ref_count=1

Filtration Range Number Termination Point Removal Inventory
    [Documentation]    Test processing of termination point removal using filtration operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    #Create the original topology
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OPENFLOW_NODE_CONNECTOR_PORT_NUMBER}
    ${request}    Set Range Number Filter    ${request}    2    4
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=5    tp-ref_count=5
    #Remove an underlay filtered termination point
    Delete Underlay Termination Point    openflow-topo:1    of-node:3    tp:3:2
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=4    tp-ref_count=4
    #Remove an underlay filtered termination point
    Delete Underlay Termination Point    openflow-topo:1    of-node:3    tp:3:1
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3

Filtration Range Number Link Removal NT
    [Documentation]    Test processing of link removal using filtration operation on NT model
    #Create the original topology
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${IGP_LINK_METRIC}
    ${request}    Set Range Number Filter    ${request}    11    13
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=3    link-ref_count=3
    #Remove an underlay filtered link, expecting removal of the overlay link
    Delete Underlay Link    network-topo:1    link:1:3
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=2    link-ref_count=2

Filtration Range Number Link Removal Inventory
    [Documentation]    Test processing of link removal using filtration operation on Inventory model
    #Create the original topology
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${IGP_LINK_METRIC}
    ${request}    Set Range Number Filter    ${request}    14    15
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=2    link-ref_count=2
    #Remove an underlay filtered link, expecting removal of the overlay link
    Delete Underlay Link    openflow-topo:3    link:14:12
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=1    link-ref_count=1

Unification Filtration Node Removal Inside NT
    [Documentation]    Test processing of node removal using unification with filtration operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    ${model}    node    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    network-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    #Remove an underlay aggregated node, preserving the overlay node
    Delete Underlay Node    network-topo:4    bgp:20
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=2
    ...    node-ref_count=2    tp_count=0    tp-ref_count=0
    #Remove an underlay aggregated node, expecting removal of the overlay node
    Delete Underlay Node    network-topo:4    bgp:18
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=1    supporting-node_count=1
    ...    node-ref_count=1    tp_count=0    tp-ref_count=0

Unification Filtration Node Removal Inside Inventory
    [Documentation]    Test processing of node removal using unification with filtration operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    ${model}    node    ${OPENFLOW_NODE_IP_ADDRESS}    openflow-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${OPENFLOW_NODE_IP_ADDRESS}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=4
    ...    node-ref_count=4    tp_count=0    tp-ref_count=0
    #Remove an underlay aggregated node, preserving the overlay node
    Delete Underlay Node    openflow-topo:4    of-node:17
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    #Remove an underlay aggregated node, expecting removal of the overlay node
    Delete Underlay Node    openflow-topo:4    of-node:18
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=1    supporting-node_count=2
    ...    node-ref_count=2    tp_count=0    tp-ref_count=0

Link Computation Aggregation Inside Node Removal NT
    [Documentation]    Test processing of node removal using unification with link computation operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    ${model}    node    network-topo:6
    ${request}    Insert Target Field    ${request}    0    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=5
    ...    node-ref_count=5    link_count=4    link-ref_count=4
    Delete Underlay Node    network-topo:6    bgp:26
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=4
    ...    node-ref_count=4    link_count=3    link-ref_count=3
    Delete Underlay Node    network-topo:6    bgp:28
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    link_count=2    link-ref_count=2

Link Computation Aggregation Inside Link Removal NT
    [Documentation]    Test processing of link removal using unification with link computation operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    ${model}    node    network-topo:6
    ${request}    Insert Target Field    ${request}    0    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=5
    ...    node-ref_count=5    link_count=4    link-ref_count=4
    Delete Underlay Link    network-topo:6    link:26:28
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=5
    ...    node-ref_count=5    link_count=3    link-ref_count=3

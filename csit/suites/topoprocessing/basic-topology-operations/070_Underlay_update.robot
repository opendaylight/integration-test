*** Settings ***
Documentation     Test suite to verify update behaviour during different topoprocessing operations on NT and inventory models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIG_API to OPERATIONAL_API.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Suite setup also installs features required for tested models and clears karaf logs for further synchronization. Tests themselves send configurational
...               xmls and verify output. Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
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
Unification Node Update
    [Documentation]    Test processing of updates using unification operation on Network Topology model
    #Create the original topology
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    ${model}    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    ${request}    Insert Target Field    ${request}    1    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=8    supporting-node_count=10
    ...    tp_count=14    tp-ref_count=14
    #Update a node, expecting a unification of two nodes into one
    ${node}    Create Isis Node    bgp:1    router-id-ipv4=192.168.1.2
    Basic Request Put    ${node}    network-topology:network-topology/topology/network-topo:1/node/bgp:1
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=7    supporting-node_count=10
    ...    tp_count=11    tp-ref_count=11
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:2    bgp:1
    #Update a unified node, expecting creation of a new overlay node
    ${node}    Create Isis Node    bgp:3    router-id-ipv4=192.168.3.1
    Basic Request Put    ${node}    network-topology:network-topology/topology/network-topo:1/node/bgp:3
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=8    supporting-node_count=10
    ...    tp_count=9    tp-ref_count=9
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1

Unification Node Inventory
    [Documentation]    Test processing of updates using unification operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    ${model}    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    ${OPENFLOW_NODE_IP_ADDRESS}    0
    ${request}    Insert Target Field    ${request}    1    ${OPENFLOW_NODE_IP_ADDRESS}    0
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=7    supporting-node_count=10
    ...    tp_count=12    tp-ref_count=12
    #Update a node, expecting unification of two nodes into one
    ${node}    Create Openflow Node    openflow:2    192.168.1.1
    Basic Request Put    ${node}    opendaylight-inventory:nodes/node/openflow:2
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=6    supporting-node_count=10
    ...    tp_count=12    tp-ref_count=12
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    Check Aggregated Node in Topology    ${model}    ${resp.content}    5    of-node:2    of-node:6    of-node:1
    #Update a unified node, expecting creation of a new overlay node
    ${node}    Create Openflow Node    openflow:4    192.168.3.1
    Basic Request Put    ${node}    opendaylight-inventory:nodes/node/openflow:4
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=7    supporting-node_count=10
    ...    tp_count=12    tp-ref_count=12
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1

Filtration Range Number Node Update Network Topology Model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OVSDB_OVS_VERSION}
    ${request}    Set Range Number Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=4
    ...    node-ref_count=4    tp_count=5    tp-ref_count=5
    ${request}    Create Isis Node    bgp:7    17
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:2/node/bgp:7
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=3    tp-ref_count=3
    : FOR    ${index}    IN RANGE    8    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Should Not Contain    ${resp.content}    <node-ref>bgp:7</node-ref>
    ${topology_id}    Set Variable    network-topo:2
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:8    tp:8:1    tp:8:1
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:9    tp:9:1    tp:9:1
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:10    tp:10:1    tp:10:1
    ${request}    Create Isis Node    bgp:7    23
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:2/node/bgp:7
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=4
    ...    node-ref_count=4    tp_count=3    tp-ref_count=3
    ${request}    Create OVSDB Termination Point    tp:7:1    1119
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:1
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=4
    ...    node-ref_count=4    tp_count=4    tp-ref_count=4
    : FOR    ${index}    IN RANGE    7    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:7    tp:7:1    tp:7:1
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:8    tp:8:1    tp:8:1
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:9    tp:9:1    tp:9:1
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    ${topology_id}    bgp:10    tp:10:1    tp:10:1

Filtration Range Number Node Update Inventory Model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OPENFLOW_NODE_SERIAL_NUMBER}
    ${request}    Set Range Number Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    #Update a Node so it passes filtration
    ${request}    Create Openflow Node    openflow:7    192.168.2.3    23
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:7
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=4
    ...    node-ref_count=4    tp_count=0    tp-ref_count=0
    : FOR    ${index}    IN RANGE    7    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    #Update a Node so it is filtered out
    ${request}    Create Openflow Node    openflow:7    192.168.2.3    17
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:7
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    : FOR    ${index}    IN RANGE    8    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    Should Not Contain    ${resp.content}    <node-ref>of-node:7</node-ref>

Filtration Range Number Termination Point Update NT
    [Documentation]    Test processing of updates using range number type of filtration operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OVSDB_OFPORT}
    ${request}    Set Range Number Filter    ${request}    1115    1119
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    #Update a previously out-of-range termination point, so it passes filtration
    ${terminationPoint}    Create OVSDB Termination Point    tp:8:1    1115
    Basic Request Put    ${terminationPoint}    network-topology:network-topology/topology/network-topo:2/node/bgp:8/termination-point/tp:8:1
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=4    tp-ref_count=4
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    network-topo:2    bgp:8    tp:8:1    tp:8:1
    #Update a previsouly in-range termination point, so it is filtered out
    ${terminationPoint}    Create OVSDB Termination Point    tp:7:2    1110
    Basic Request Put    ${terminationPoint}    network-topology:network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:2
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=3    tp-ref_count=3
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    network-topo:2    bgp:7    tp:7:1    tp:7:1

Filtration Range Number Termination Point Update Inventory
    [Documentation]    Test processing of updates using range number type of filtration operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    ${model}    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OPENFLOW_NODE_CONNECTOR_PORT_NUMBER}
    ${request}    Set Range Number Filter    ${request}    2    4
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=5    tp-ref_count=5
    #Update a previously out-of-range termination point, so it passes filtration
    ${nodeConnector}    Create Openflow Node Connector    openflow:2:1    3
    Basic Request Put    ${nodeConnector}    opendaylight-inventory:nodes/node/openflow:2/node-connector/openflow:2:1
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=6    tp-ref_count=6
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    openflow-topo:1    of-node:2    tp:2:1    tp:2:1
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    openflow-topo:1    of-node:2    tp:2:2    tp:2:2
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    openflow-topo:1    of-node:2    tp:2:3    tp:2:3
    #Update an in-range termination point, so it is filtered out
    ${nodeConnector}    Create Openflow Node Connector    openflow:3:2    5
    Basic Request Put    ${nodeConnector}    opendaylight-inventory:nodes/node/openflow:3/node-connector/openflow:3:2
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    tp_count=5    tp-ref_count=5
    Check Aggregated Termination Point in Node    ${model}    ${resp.content}    openflow-topo:1    of-node:3    tp:3:1    tp:3:1

Filtration Range Number Link Update Network Topology Model
    [Documentation]    Tests the processing of link update requests when using a range-number filtration on NT model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${IGP_LINK_METRIC}
    ${request}    Set Range Number Filter    ${request}    11    13
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=3    link-ref_count=3
    #Filter a link out
    ${request}    Create Link    link:1:4    bgp:1    bgp:4    linkA    15
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:1/link/link:1:4
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=2    link-ref_count=2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:3</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-1</link-ref>    1
    Should Not Contain    ${resp.content}    network-topology/topology/network-topo:1/link/link:1:4
    #Put the link back in
    ${request}    Create Link    link:1:4    bgp:1    bgp:4    linkA    12
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:1/link/link:1:4
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=3    link-ref_count=3
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:4</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:3</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-1</link-ref>    1

Filtration Range Number Link Update Inventory Model
    [Documentation]    Tests the processing of link update requests when using a range-number filtration on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${IGP_LINK_METRIC}
    ${request}    Set Range Number Filter    ${request}    14    15
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=2    link-ref_count=2
    ${request}    Create Link    link:11:12    of-node:11    of-node:12    linkB    14
    Basic Request Put    ${request}    network-topology:network-topology/topology/openflow-topo:3/link/link:11:12
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=3    link-ref_count=3
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:14:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:11:12</link-ref>    1
    ${request}    Create Link    link:11:12    of-node:11    of-node:12    linkB    13
    Basic Request Put    ${request}    network-topology:network-topology/topology/openflow-topo:3/link/link:11:12
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    link_count=2    link-ref_count=2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:14:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1

Unification Filtration Node Update Inside Network Topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    ${model}    node    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    network-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    ${request}    Create Isis Node    bgp:17    10    192.168.2.1
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:4/node/bgp:17
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=4
    ...    node-ref_count=4    tp_count=0    tp-ref_count=0
    : FOR    ${index}    IN RANGE    17    21
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:18    bgp:17    bgp:20
    ${request}    Create Isis Node    bgp:17    10    192.168.1.2
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:4/node/bgp:17
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    : FOR    ${index}    IN RANGE    18    21
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:18    bgp:20

Unification Filtration Node Update Inside Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    ${model}    node    ${OPENFLOW_NODE_IP_ADDRESS}    openflow-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    ${OPENFLOW_NODE_IP_ADDRESS}    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=4
    ...    node-ref_count=4    tp_count=0    tp-ref_count=0
    ${request}    Create Openflow Node    openflow:17    192.168.1.2
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:17
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    : FOR    ${index}    IN RANGE    18    21
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:19']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <node-ref>of-node:19</node-ref>
    Should Contain    ${node}    <node-ref>of-node:20</node-ref>
    Should Not Contain    ${node}    <node-ref>of-node:17</node-ref>
    ${request}    Create Openflow Node    openflow:17    192.168.2.3
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:17
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=4
    ...    node-ref_count=4    tp_count=0    tp-ref_count=0
    : FOR    ${index}    IN RANGE    17    21
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    of-node:17    of-node:19    of-node:20

Link Computation Aggregation Inside Update NT
    [Documentation]    Test of link computation with unification type of aggregation inside on updated nodes from network-topology model
    ${model}    Set Variable    network-topology-model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    ${model}    node    network-topo:6
    ${request}    Insert Target Field    ${request}    0    ${ISIS_NODE_TE_ROUTER_ID_IPV4}    0
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=5
    ...    node-ref_count=5    link_count=4    link-ref_count=4
    #Divide double nodes from overlay topology
    ${request}    Create Isis Node    bgp:29    router-id-ipv4=192.168.1.3
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:6/node/bgp:29
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    link_count=4    link-ref_count=4
    ${node_26}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:26
    ${node_27}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:27
    ${node_28}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:28
    ${node_29}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:29
    ${node_30}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:30
    ${topo_id}    Set Variable    network-topo:6
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:28:29    ${node_28}    ${node_29}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:26:28    ${node_26}    ${node_28}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:29:30-2    ${node_29}    ${node_30}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:29:30-1    ${node_29}    ${node_30}
    #Update link to node out of topology
    ${request}    Create Link    link:28:29    bgp:28    bgp:31    linkB    11
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:6/link/link:28:29
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=5    supporting-node_count=5
    ...    node-ref_count=5    link_count=3    link-ref_count=3
    #Refresh node IDs
    ${node_26}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:26
    ${node_27}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:27
    ${node_28}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:28
    ${node_29}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:29
    ${node_30}    Check Aggregated Node in Topology    ${model}    ${resp.content}    0    bgp:30
    Should Not Contain    ${resp.content}    /network-topology/topology/network-topo:6/link/link:28:29
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:26:28    ${node_26}    ${node_28}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:29:30-2    ${node_29}    ${node_30}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:29:30-1    ${node_29}    ${node_30}
    Check Overlay Link Source And Destination    ${model}    ${resp.content}    ${topo_id}    link:29:30-1    ${node_29}    ${node_30}

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
Filtration IPV4 Network Topology Model
    [Documentation]    Test of ipv4 type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=2
    ...    node-ref_count=2    tp_count=3    tp-ref_count=3
    Check Filtered Nodes in Topology    ${resp.content}    3    bgp:1    bgp:2

Filtration IPV4 Inventory Model
    [Documentation]    Test of ipv4 type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    ${OPENFLOW_NODE_IP_ADDRESS}
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=8    tp-ref_count=8
    Check Filtered Nodes in Topology    ${resp.content}    8    of-node:1    of-node:2    of-node:3

Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OVSDB_OVS_VERSION}
    ${request}    Set Range Number Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=4
    ...    node-ref_count=4    tp_count=5    tp-ref_count=5
    Check Filtered Nodes in Topology    ${resp.content}    5    bgp:7    bgp:8    bgp:9    bgp:10

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${OPENFLOW_NODE_SERIAL_NUMBER}
    ${request}    Set Range Number Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    Check Filtered Nodes in Topology    ${resp.content}    0    of-node:8    of-node:9    of-node:10

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ${OVSDB_OVS_VERSION}
    ${request}    Set Specific String Filter    ${request}    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=2
    ...    node-ref_count=2    tp_count=2    tp-ref_count=2
    Check Filtered Nodes in Topology    ${resp.content}    2    bgp:9    bgp:10

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ${OPENFLOW_NODE_SERIAL_NUMBER}
    ${request}    Set Specific String Filter    ${request}    21
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=2
    ...    node-ref_count=2    tp_count=0    tp-ref_count=0
    Check Filtered Nodes in Topology    ${resp.content}    0    of-node:8    of-node:9

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ${OVSDB_OVS_VERSION}
    ${request}    Set Range String Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=4    supporting-node_count=4
    ...    node-ref_count=4    tp_count=5    tp-ref_count=5
    Check Filtered Nodes in Topology    ${resp.content}    5    bgp:7    bgp:8    bgp:9    bgp:10

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ${OPENFLOW_NODE_SERIAL_NUMBER}
    ${request}    Set Range String Filter    ${request}    20    25
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    Check Filtered Nodes in Topology    ${resp.content}    0    of-node:8    of-node:9    of-node:10

Filtration IPV6 Network Topology Model
    [Documentation]    Test of ipv6 type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_IPV6}    ${ISIS_NODE_TE_ROUTER_ID_IPV6}
    ${request}    Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:101/120
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=2    supporting-node_count=2
    ...    node-ref_count=2    tp_count=1    tp-ref_count=1
    Check Filtered Nodes in Topology    ${resp.content}    1    bgp:11    bgp:12

Filtration IPV6 Inventory Model
    [Documentation]    Test of ipv6 type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_IPV6}    ${OPENFLOW_NODE_IP_ADDRESS}
    ${request}    Set IPV6 Filter    ${request}    fe80:0:0:0:0:0:c0a8:201/120
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=0    tp-ref_count=0
    Check Filtered Nodes in Topology    ${resp.content}    0    of-node:12    of-node:14    of-node:15

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ${ISIS_NODE_TE_ROUTER_ID_IPV4}
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.1") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=5    tp-ref_count=5
    Check Filtered Nodes in Topology    ${resp.content}    5    bgp:3    bgp:4    bgp:5

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ${OPENFLOW_NODE_IP_ADDRESS}
    ${script}    Set Variable    if (node.getValue().indexOf("192.168.2") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    Basic Request Put    ${request}    ${OVERLAY_TOPO_URL}
    ${resp}    Wait Until Keyword Succeeds    3x    1s    Output Topo Should Be Complete    node_count=3    supporting-node_count=3
    ...    node-ref_count=3    tp_count=8    tp-ref_count=8
    Check Filtered Nodes in Topology    ${resp.content}    8    of-node:1    of-node:2    of-node:3

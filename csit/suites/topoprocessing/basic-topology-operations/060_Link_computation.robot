*** Settings ***
Documentation     Test suite to verify fitration operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/topoprocessing/Topologies.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Test Cases ***
Link Computation Aggregation Inside
    [Documentation]    Test of link computation with unification inside on Network Topology model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:6
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    4
    Should Contain X Times    ${resp.content}    <node-ref>bgp:26</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:27</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:30</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:28']/..
    ${node_id}    Get Element Text    ${node}    xpath=./node-id
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <node-ref>bgp:28</node-ref>
    Should Contain    ${node}    <node-ref>bgp:29</node-ref>
    Should Contain X Times    ${resp.content}    <link>    4
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:28:29']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${node_id}    ${source}
    Should Be Equal    ${node_id}    ${destination}
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:30']/..
    ${node_id}    Get Element Text    ${node}    xpath=./node-id
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:29']/..
    ${source_node_id}    Get Element Text    ${node}    xpath=./node-id
    Should Contain X Times    ${resp.content}    <link>    4
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:29:30-2']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${node_id}    ${destination}
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Link Computation Filtration
    [Documentation]    Test of link computation with filtration on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:6
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    3
    Should Contain X Times    ${resp.content}    <node-ref>bgp:28</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:29</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:30</node-ref>    1
    Should Contain X Times    ${resp.content}    <link>    3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:28']/..
    ${source_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:29']/..
    ${destination_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:28:29']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${destination_node_id}    ${destination}
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:29']/..
    ${source_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:30']/..
    ${destination_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:29:30-2']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${destination_node_id}    ${destination}
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:29:30-1']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${destination_node_id}    ${destination}
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Link Computation Aggregation Filtration
    [Documentation]    Test of link computation with aggregation filtration on Network Topology model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT}    network-topology-model    node    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:6
    ${request}    Prepare Unification Filtration Topology Request    ${request}    network-topology-model    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    ${request}    Insert Link Computation    ${request}    ${LINK_COMPUTATION}    n:network-topology-model    network-topo:6    network-topo:1
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <node-ref>bgp:1</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:2</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:3</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:4</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:5</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:28</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:29</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:30</node-ref>    1
    Should Contain X Times    ${resp.content}    <link>    7
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:28']/..
    ${source_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:29']/..
    ${destination_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:28:29']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${destination_node_id}    ${destination}
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:29']/..
    ${source_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:30']/..
    ${destination_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:29:30-2']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${destination_node_id}    ${destination}
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:29:30-1']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${destination_node_id}    ${destination}
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${source_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:4']/..
    ${destination_node_id}    Get Element Text    ${node}    xpath=./node-id
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='link:1:4']/..
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal    ${source_node_id}    ${source}
    Should Be Equal    ${destination_node_id}    ${destination}
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

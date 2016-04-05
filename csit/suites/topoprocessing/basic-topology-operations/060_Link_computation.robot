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
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    network-topo:6
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <link-id>    4
    #nodes 29 and 28
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:28']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:29</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:28</node-ref>    1
    ${node_29}    Get Element Text    ${node}    xpath=./node-id
    ${node_28}    Get Element Text    ${node}    xpath=./node-id
    #node 26
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:26']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:26</node-ref>    1
    ${node_26}    Get Element Text    ${node}    xpath=./node-id
    #node 30
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:30']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:30</node-ref>    1
    ${node_30}    Get Element Text    ${node}    xpath=./node-id
    #node 27
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:27']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:27</node-ref>    1
    ${node_27}    Get Element Text    ${node}    xpath=./node-id
    #link 28-29
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='/network-topology/topology/network-topo:6/link/link:28:29']/..
    ${link}    Element to String    ${link}
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${source}    ${node_28}
    Should Be Equal As Strings    ${destination}    ${node_29}
    #link 26-28
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='/network-topology/topology/network-topo:6/link/link:26:28']/..
    ${link}    Element to String    ${link}
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${source}    ${node_26}
    Should Be Equal As Strings    ${destination}    ${node_28}
    #link 29:30-2
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='/network-topology/topology/network-topo:6/link/link:29:30-2']/..
    ${link}    Element to String    ${link}
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${source}    ${node_29}
    Should Be Equal As Strings    ${destination}    ${node_30}
    #link 29:30-1
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='/network-topology/topology/network-topo:6/link/link:29:30-1']/..
    ${link}    Element to String    ${link}
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${source}    ${node_29}
    Should Be Equal As Strings    ${destination}    ${node_30}

Link Computation Filtration
    [Documentation]    Test of link computation with filtration on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:6
    ${request}    Insert Filter    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/32
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-ref>bgp:28</node-ref>    1
    Should Contain X Times    ${resp.content}    <node-ref>bgp:29</node-ref>    1
    Should Contain X Times    ${resp.content}    <link>    1
    #node 28
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:28']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:28</node-ref>    1
    ${node_28}    Get Element Text    ${node}    xpath=./node-id
    #node 29
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:29']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:29</node-ref>    1
    ${node_29}    Get Element Text    ${node}    xpath=./node-id
    #link 28-29
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='/network-topology/topology/network-topo:6/link/link:28:29']/..
    ${link}    Element to String    ${link}
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${source}    ${node_28}
    Should Be Equal As Strings    ${destination}    ${node_29}

Link Computation Aggregation Filtration
    [Documentation]    Test of link computation with aggregation filtration on Network Topology model
    ${target_field}    Set Variable    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4
    ${request}    Prepare Unification Filtration Topology Request    ${UNIFICATION_FILTRATION_NT}    network-topology-model    node    ${target_field}    network-topo:6
    ...    ${target_field}    network-topo:1
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Insert Apply Filters    ${request}    2    1
    ${request}    Set IPV4 Filter    ${request}    192.168.1.1/24
    ${request}    Insert Link Computation    ${request}    ${LINK_COMPUTATION}    n:network-topology-model    network-topo:6    network-topo:1
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <link>    2
    #nodes 26 and 1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:26']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:26</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:1</node-ref>    1
    ${node_26}    Get Element Text    ${node}    xpath=./node-id
    ${node_1}    Get Element Text    ${node}    xpath=./node-id
    #nodes 27 and 2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:27']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:27</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:2</node-ref>    1
    ${node_27}    Get Element Text    ${node}    xpath=./node-id
    ${node_2}    Get Element Text    ${node}    xpath=./node-id
    #link 1:2-1
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='/network-topology/topology/network-topo:1/link/link:1:2-1']/..
    ${link}    Element to String    ${link}
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${source}    ${node_1}
    Should Be Equal As Strings    ${destination}    ${node_2}
    #link 1:2-2
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='/network-topology/topology/network-topo:1/link/link:1:2-2']/..
    ${link}    Element to String    ${link}
    ${source}    Get Element Text    ${link}    xpath=.//source-node
    ${destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${source}    ${node_26}
    Should Be Equal As Strings    ${destination}    ${node_27}

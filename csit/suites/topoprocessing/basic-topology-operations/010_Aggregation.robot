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
Unification Node
    [Documentation]    Test unification operation on Network Topology model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Target Field    ${request}    1    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    8
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    1    10
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:10']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:10</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:5</node-ref>    1

Unification Node Inventory
    [Documentation]    Test unification operation on inventory model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${request}    Insert Target Field    ${request}    1    flow-node-inventory:ip-address    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    7
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:6</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:1</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:10</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:4</node-ref>    1

Unification Scripting Node
    [Documentation]    Test unification operation on Network Topology model using scripting
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Target Field    ${request}    1    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Scripting into Request    ${request}    javascript    if (originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.1") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.3") > -1 || originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.3") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.1") > -1) {aggregable.setResult(true);} else { aggregable.setResult(false);}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    9
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>bgp:1</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>bgp:6</node-ref>    1

Unification Scripting Node Inventory
    [Documentation]    Test unification operation on inventory model using scripting
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${request}    Insert Target Field    ${request}    1    flow-node-inventory:ip-address    0
    ${request}    Insert Scripting into Request    ${request}    javascript    if (originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.2") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.4") > -1 || originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.4") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.2") > -1) {aggregable.setResult(true);} else { aggregable.setResult(false);}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    9
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <node-ref>of-node:2</node-ref>    1
    Should Contain X Times    ${node}    <node-ref>of-node:8</node-ref>    1

Unification Node Inside
    [Documentation]    Test of unification type of aggregation inside on nodes on Network Topology model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    network-topo:1
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    ${response_xml}    Parse XML    ${resp.content}
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='bgp:3']/..
    ${node}    Element To String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <supporting-node><node-ref>bgp:3</node-ref>
    Should Contain    ${node}    <supporting-node><node-ref>bgp:4</node-ref>

Unification Node Inside Inventory
    [Documentation]    Test of unification type of aggregation inside on nodes on Inventory model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    ${response_xml}    Parse XML    ${resp.content}
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='of-node:7']/..
    ${node}    Element To String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <supporting-node><node-ref>of-node:7</node-ref>
    Should Contain    ${node}    <supporting-node><node-ref>of-node:9</node-ref>

Unification Termination Point Inside
    [Documentation]    Test aggregate inside operation on termination points
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    termination-point    network-topo:1
    ${request}    Insert Target Field    ${request}    0    ovsdb:ofport    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    6
    # bgp:1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:3']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:3</tp-ref>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:1']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:1</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:1/termination-point/tp:1:2</tp-ref>    1
    # bgp:3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/network-topo:1/node/bgp:3/termination-point/tp:3:2']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:3/termination-point/tp:3:2</tp-ref>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/network-topo:1/node/bgp:3/termination-point/tp:3:1']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:3/termination-point/tp:3:1</tp-ref>    1
    # bgp:4
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/network-topo:1/node/bgp:4/termination-point/tp:4:1']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:4/termination-point/tp:4:1</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:4/termination-point/tp:4:2</tp-ref>    1
    # bgp:5
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/network-topo:1/node/bgp:5/termination-point/tp:5:1']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/network-topo:1/node/bgp:5/termination-point/tp:5:1</tp-ref>    1

Unification Termination Point Inside Inventory
    [Documentation]    Test aggregate inside operation on termination points
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:port-number    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <termination-point>    8
    # of-node:1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:1/termination-point/tp:1:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:1/termination-point/tp:1:2</tp-ref>    1
    # of-node:2
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:2']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    3
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:2']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:2</tp-ref>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:1']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:2:1</tp-ref>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:3']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:2/termination-point/tp:3</tp-ref>    1
    # of-node:3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:3']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:3</tp-ref>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:2']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:2</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:3/termination-point/tp:3:1</tp-ref>    1
    # of-node:4
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:4/termination-point/tp:4:1</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:4/termination-point/tp:4:2</tp-ref>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:4/termination-point/tp:4:3</tp-ref>    1
    # of-node:5
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:5']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    Should Contain X Times    ${node}    <tp-ref>/network-topology:network-topology/topology/openflow-topo:1/node/of-node:5/termination-point/tp:5:1</tp-ref>    1

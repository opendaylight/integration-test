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
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    9
    Should Contain X Times    ${resp.content}    <supporting-node>    10
    Should Contain X Times    ${resp.content}    <termination-point    14
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    14
    @{empty_list}    Create List
    @{supp_node_ids}    Create List    bgp:5    bgp:10
    @{supp_tp_ids}    Create List    tp:5:1    tp:10:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:10']/..    ${supp_tp_ids}    @{supp_node_ids}
    @{supp_tp_ids}    Create List    tp:9:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:9']/..    ${supp_tp_ids}    bgp:9
    @{supp_tp_ids}    Create List    tp:8:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:8']/..    ${supp_tp_ids}    bgp:8
    @{supp_tp_ids}    Create List    tp:7:1    tp:7:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:7']/..    ${supp_tp_ids}    bgp:7
    @{supp_tp_ids}    Create List    tp:6:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:6']/..    ${supp_tp_ids}    bgp:6
    @{supp_tp_ids}    Create List    tp:4:1    tp:4:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:4']/..    ${supp_tp_ids}    bgp:4
    @{supp_tp_ids}    Create List    tp:3:1    tp:3:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:3']/..    ${supp_tp_ids}    bgp:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:2']/..    ${empty_list}    bgp:2
    @{supp_tp_ids}    Create List    tp:1:1    tp:1:2    tp:1:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:1']/..    ${supp_tp_ids}    bgp:1

Unification Node Inventory
    [Documentation]    Test unification operation on inventory model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${request}    Insert Target Field    ${request}    1    flow-node-inventory:ip-address    0
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    8
    Should Contain X Times    ${resp.content}    <supporting-node>    10
    Should Contain X Times    ${resp.content}    <termination-point    12
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    12
    @{empty_list}    Create List
    @{supp_node_ids}    Create List    of-node:10    of-node:4
    @{supp_tp_ids}    Create List    tp:4:1    tp:4:2    tp:4:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:10']/..    ${supp_tp_ids}    @{supp_node_ids}
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:9']/..    ${empty_list}    of-node:9
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:8']/..    ${empty_list}    of-node:8
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:7']/..    ${empty_list}    of-node:7
    @{supp_node_ids}    Create List    of-node:6    of-node:1
    @{supp_tp_ids}    Create List    tp:1:1    tp:1:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:6']/..    ${supp_tp_ids}    @{supp_node_ids}
    @{supp_tp_ids}    Create List    tp:5:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:5']/..    ${supp_tp_ids}    of-node:5
    @{supp_tp_ids}    Create List    tp:3:1    tp:3:2    tp:3:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:3']/..    ${supp_tp_ids}    of-node:3
    @{supp_tp_ids}    Create List    tp:2:1    tp:2:2    tp:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:2']/..    ${supp_tp_ids}    of-node:2

Unification Scripting Node
    [Documentation]    Test unification operation on Network Topology model using scripting
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Target Field    ${request}    1    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Scripting into Request    ${request}    javascript    if (originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.1") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.3") > -1 || originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.3") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.1") > -1) {aggregable.setResult(true);} else { aggregable.setResult(false);}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    9
    Should Contain X Times    ${resp.content}    <supporting-node>    10
    Should Contain X Times    ${resp.content}    <termination-point    14
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    14
    @{empty_list}    Create List
    @{supp_tp_ids}    Create List    tp:10:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:10']/..    ${supp_tp_ids}    bgp:10
    @{supp_tp_ids}    Create List    tp:9:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:9']/..    ${supp_tp_ids}    bgp:9
    @{supp_tp_ids}    Create List    tp:8:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:8']/..    ${supp_tp_ids}    bgp:8
    @{supp_tp_ids}    Create List    tp:7:1    tp:7:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:7']/..    ${supp_tp_ids}    bgp:7
    @{supp_node_ids}    Create List    bgp:1    bgp:6
    @{supp_tp_ids}    Create List    tp:1:1    tp:1:2    tp:1:3    tp:6:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:6']/..    ${supp_tp_ids}    @{supp_node_ids}
    @{supp_tp_ids}    Create List    tp:5:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:5']/..    ${supp_tp_ids}    bgp:5
    @{supp_tp_ids}    Create List    tp:4:1    tp:4:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:4']/..    ${supp_tp_ids}    bgp:4
    @{supp_tp_ids}    Create List    tp:3:1    tp:3:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:3']/..    ${supp_tp_ids}    bgp:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:2']/..    ${empty_list}    bgp:2

Unification Scripting Node Inventory
    [Documentation]    Test unification operation on inventory model using scripting
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${request}    Insert Target Field    ${request}    1    flow-node-inventory:ip-address    0
    ${request}    Insert Scripting into Request    ${request}    javascript    if (originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.2") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.4") > -1 || originalItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.4") > -1 && newItem.getLeafNodes().get(java.lang.Integer.valueOf('0')).getValue().indexOf("192.168.1.2") > -1) {aggregable.setResult(true);} else { aggregable.setResult(false);}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    9
    Should Contain X Times    ${resp.content}    <supporting-node>    10
    Should Contain X Times    ${resp.content}    <termination-point    12
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    12
    @{empty_list}    Create List
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:10']/..    ${empty_list}    of-node:10
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:9']/..    ${empty_list}    of-node:9
    @{supp_node_ids}    Create List    of-node:2    of-node:8
    @{supp_tp_ids}    Create List    tp:2:1    tp:2:2    tp:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:8']/..    ${supp_tp_ids}    @{supp_node_ids}
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:7']/..    ${empty_list}    of-node:7
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:6']/..    ${empty_list}    of-node:6
    @{supp_tp_ids}    Create List    tp:5:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:5']/..    ${supp_tp_ids}    of-node:5
    @{supp_tp_ids}    Create List    tp:4:1    tp:4:2    tp:4:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:4']/..    ${supp_tp_ids}    of-node:4
    @{supp_tp_ids}    Create List    tp:3:1    tp:3:2    tp:3:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:3']/..    ${supp_tp_ids}    of-node:3
    @{supp_tp_ids}    Create List    tp:1:1    tp:1:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:1']/..    ${supp_tp_ids}    of-node:1

Unification Node Inside
    [Documentation]    Test of unification type of aggregation inside on nodes on Network Topology model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    network-topo:1
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    4
    Should Contain X Times    ${resp.content}    <supporting-node>    5
    Should Contain X Times    ${resp.content}    <termination-point    8
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    8
    @{empty_list}    Create List
    @{supp_tp_ids}    Create List    tp:5:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:5']/..    ${supp_tp_ids}    bgp:5
    @{supp_node_ids}    Create List    bgp:3    bgp:4
    @{supp_tp_ids}    Create List    tp:4:1    tp:4:2    tp:3:1    tp:3:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:4']/..    ${supp_tp_ids}    @{supp_node_ids}
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:2']/..    ${empty_list}    bgp:2
    @{supp_tp_ids}    Create List    tp:1:1    tp:1:2    tp:1:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:1']/..    ${supp_tp_ids}    bgp:1

Unification Node Inside Inventory
    [Documentation]    Test of unification type of aggregation inside on nodes on Inventory model
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    4
    Should Contain X Times    ${resp.content}    <supporting-node>    5
    Should Contain X Times    ${resp.content}    <termination-point    0
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    0
    @{empty_list}    Create List
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:10']/..    ${empty_list}    of-node:10
    @{supp_node_ids}    Create List    of-node:7    of-node:9
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:9']/..    ${empty_list}    @{supp_node_ids}
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:8']/..    ${empty_list}    of-node:8
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:6']/..    ${empty_list}    of-node:6

Unification Termination Point Inside
    [Documentation]    Test aggregate inside operation on termination points
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    termination-point    network-topo:1
    ${request}    Insert Target Field    ${request}    0    ovsdb:ofport    0
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <supporting-node>    5
    Should Contain X Times    ${resp.content}    <termination-point    6
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    8
    # without aggregated TPs
    @{empty_list}    Create List
    @{supp_tp_ids}    Create List    tp:5:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:5']/..    ${supp_tp_ids}    bgp:5
    @{supp_tp_ids}    Create List    tp:3:1    tp:3:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:3']/..    ${supp_tp_ids}    bgp:3
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='bgp:2']/..    ${empty_list}    bgp:2
    # with aggregated TPs
    # bgp:4
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <supporting-termination-point>    2
    Should Contain X Times    ${tp}    <tp-ref>tp:4:1</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:4:2</tp-ref>    1
    # bgp:1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='bgp:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point    2
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='tp:1:3']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <supporting-termination-point>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:1:3</tp-ref>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='tp:1:1']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <supporting-termination-point>    2
    Should Contain X Times    ${tp}    <tp-ref>tp:1:1</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:1:2</tp-ref>    1

Unification Termination Point Inside Inventory
    [Documentation]    Test aggregate inside operation on termination points
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:port-number    0
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Should Contain X Times    ${resp.content}    <node>    5
    Should Contain X Times    ${resp.content}    <supporting-node>    5
    Should Contain X Times    ${resp.content}    <termination-point    8
    Should Contain X Times    ${resp.content}    <supporting-termination-point>    12
    # without aggregated TPs
    @{supp_tp_ids}    Create List    tp:5:1
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:5']/..    ${supp_tp_ids}    of-node:5
    @{supp_tp_ids}    Create List    tp:2:1    tp:2:2
    Check Aggregated Node in Network    ${resp.content}    .//node/supporting-node[node-ref='of-node:2']/..    ${supp_tp_ids}    of-node:2
    # with aggregated TPs
    # of-node:4
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:4']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <supporting-termination-point>    3
    Should Contain X Times    ${tp}    <tp-ref>tp:4:1</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:4:2</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:4:3</tp-ref>    1
    # of-node:3
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:3']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point    2
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='tp:3:3']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <supporting-termination-point>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:3:3</tp-ref>    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point[tp-ref='tp:3:1']
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <supporting-termination-point>    2
    Should Contain X Times    ${tp}    <tp-ref>tp:3:1</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:3:2</tp-ref>    1
    # of-node:1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:1']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point    1
    ${tp}    Get Element    ${node}    xpath=.//termination-point
    ${tp}    Element to String    ${tp}
    Should Contain X Times    ${tp}    <supporting-termination-point>    2
    Should Contain X Times    ${tp}    <tp-ref>tp:1:1</tp-ref>    1
    Should Contain X Times    ${tp}    <tp-ref>tp:1:2</tp-ref>    1

*** Keywords ***
Check Aggregated Node in Network
    [Arguments]    ${network}    ${xpath}    ${supp_tp_ids}    @{supp_node_ids}
    ${aggregated_node}    Get Element    ${network}    xpath=${xpath}
    ${aggregated_node}    Element to String    ${aggregated_node}
    ${supp_node_count}    Get Length    ${supp_node_ids}
    ${supp_tp_count}    Get Length    ${supp_tp_ids}
    Should Contain X Times    ${aggregated_node}    <supporting-node>    ${supp_node_count}
    Should Contain X Times    ${aggregated_node}    <termination-point    ${supp_tp_count}
    Should Contain X Times    ${aggregated_node}    <supporting-termination-point>    ${supp_tp_count}
    : FOR    ${supp_node_id}    IN    @{supp_node_ids}
    \    Element Text Should Be    ${aggregated_node}    ${supp_node_id}    xpath=.//supporting-node[node-ref='${supp_node_id}']/node-ref
    : FOR    ${supp_tp_id}    IN    @{supp_tp_ids}
    \    Element Text Should Be    ${aggregated_node}    ${supp_tp_id}    xpath=.//termination-point/supporting-termination-point[tp-ref='${supp_tp_id}']/tp-ref

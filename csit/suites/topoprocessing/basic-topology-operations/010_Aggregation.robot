*** Settings ***
Documentation     Test suite to verify unification operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       KeywordsAndVariables.Setup Environment
Suite Teardown    KeywordsAndVariables.Clean Environment
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/topoprocessing/Topologies.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ./KeywordsAndVariables.robot

*** Test Cases ***
Unification node
    [Documentation]    Test unification operation on Network Topology model
    [Tags]    test
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    network-topology-model    xpath=.//correlations/output-model
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    aggregation-only    xpath=.//correlations/correlation/type
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    node    xpath=.//correlation/correlation-item
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    unification    xpath=.//correlation/aggregation/aggregation-type
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    network-topology-model    xpath=.//correlation/aggregation/mapping[underlay-topology='und-topo:1']/input-model
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address    xpath=.//correlation/aggregation/mapping[underlay-topology='und-topo:1']/target-field
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    network-topology-model    xpath=.//correlation/aggregation/mapping[underlay-topology='und-topo:2']/input-model
    ${UNIFICATION_NT}    Set Element Text    ${UNIFICATION_NT}    network-topology-pcep:path-computation-client/network-topology-pcep:ip-address    xpath=.//correlation/aggregation/mapping[underlay-topology='und-topo:2']/target-field
    ${UNIFICATION_NT}    Element to String    ${UNIFICATION_NT}
    ${resp}    Basic Aggregation    ${UNIFICATION_NT}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    9
    Should Match Regexp    ${resp.content}    <node><node-id>node:.?</node-id>((<supporting-node><node-ref>pcep:5</node-ref><topology-ref>und-topo:1</topology-ref></supporting-node>)|(<supporting-node><node-ref>pcep:10</node-ref><topology-ref>und-topo:2</topology-ref></supporting-node>)){2}(<termination-point>.*</termination-point>)*</node>
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

Unification Termination Point Inside
    [Documentation]    Test aggregate inside operation on termination points
    ${UNIFICATION_NT_AGGREGATE_INSIDE}    Set Element Text    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    xpath=.//correlations/output-model
    ${UNIFICATION_NT_AGGREGATE_INSIDE}    Set Element Text    ${UNIFICATION_NT_AGGREGATE_INSIDE}    aggregation-only    xpath=.//correlations/correlation/type
    ${UNIFICATION_NT_AGGREGATE_INSIDE}    Set Element Text    ${UNIFICATION_NT_AGGREGATE_INSIDE}    termination-point    xpath=.//correlation/correlation-item
    ${UNIFICATION_NT_AGGREGATE_INSIDE}    Set Element Text    ${UNIFICATION_NT_AGGREGATE_INSIDE}    unification    xpath=.//correlation/aggregation/aggregation-type
    ${UNIFICATION_NT_AGGREGATE_INSIDE}    Set Element Text    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    xpath=.//correlation/aggregation/mapping[underlay-topology='und-topo:1']/input-model
    ${UNIFICATION_NT_AGGREGATE_INSIDE}    Set Element Text    ${UNIFICATION_NT_AGGREGATE_INSIDE}    ovsdb:ofport    xpath=.//correlation/aggregation/mapping[underlay-topology='und-topo:1']/target-field
    ${UNIFICATION_NT_AGGREGATE_INSIDE}    Element to String    ${UNIFICATION_NT_AGGREGATE_INSIDE}
    ${resp}    Basic Aggregation    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    5
    ${response_xml}    Get Element    ${resp.content}    xpath=.//topology[topology-id='topo:1']
    ${response_xml}    Element to String    ${response_xml}
    Should Contain X Times    ${response_xml}    <termination-point>    6
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='pcep:1']/../
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='pcep:3']/../
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    2
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='pcep:4']/../
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    ${node}    Get Element    ${response_xml}    xpath=.//node/supporting-node[node-ref='pcep:5']/../
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <termination-point>    1
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

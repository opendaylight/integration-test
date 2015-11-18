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
    Should Match Regexp    ${resp.content}    <node><node-id>node:.?</node-id>((<supporting-node><node-ref>pcep:5</node-ref><topology-ref>und-topo:1</topology-ref></supporting-node>)|(<supporting-node><node-ref>pcep:10</node-ref><topology-ref>und-topo:2</topology-ref></supporting-node>)){2}</node>
    [Teardown]    Test Teardown    network-topology:network-topology/topology/topo:1

*** Settings ***
Documentation     Test suite to verify fitration operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Teardown     Delete Overlay Topology    ${OVERLAY_TOPO_URL}
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/topoprocessing/TargetFields.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Variables ***
${OVERLAY_TOPO_URL}    ${TOPOLOGY_URL}/topo:1

*** Test Cases ***
Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${IGP_LINK_METRIC}
    ${request}    Set Range Number Filter    ${request}    11    13
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:1:2-1    link:1:3    link:1:4

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ${IGP_LINK_METRIC}
    ${request}    Set Range Number Filter    ${request}    14    15
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:14:12    link:15:13

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ${IGP_LINK_NAME}
    ${request}    Set Specific String Filter    ${request}    linkA
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:1:4    link:1:2-1

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    ${IGP_LINK_NAME}
    ${request}    Set Specific String Filter    ${request}    linkD
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:15:13

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ${IGP_LINK_NAME}
    ${request}    Set Range String Filter    ${request}    linkA    linkB
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:1:2-1    link:1:3    link:1:4

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    ${IGP_LINK_NAME}
    ${request}    Set Range String Filter    ${request}    linkC    linkD
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:14:12    link:15:13

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ${IGP_LINK_NAME}
    ${script}    Set Variable    if (node.getValue().indexOf("linkA") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:1:2-2    link:1:3

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    ${IGP_LINK_NAME}
    ${script}    Set Variable    if (node.getValue().indexOf("linkA") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <link-id>link:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Filtered Links In Topology    ${resp.content}    link:11:12    link:14:12    link:15:13

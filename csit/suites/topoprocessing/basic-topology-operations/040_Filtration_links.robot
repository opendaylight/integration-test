*** Settings ***
Documentation     Test suite to verify fitration operation on different models.
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
Filtration Range Number Network Topology Model
    [Documentation]    Test of range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:metric    network-topology-model
    ${request}    Set Range Number Filter    ${request}    11    13
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:1:4    link:1:3    link:1:2-1

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:metric    opendaylight-inventory-model
    ${request}    Set Range Number Filter    ${request}    14    15
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:14:12    link:15:13

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name    network-topology-model
    ${request}    Set Specific String Filter    ${request}    linkA
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:1:4    link:1:2-1

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name    opendaylight-inventory-model
    ${request}    Set Specific String Filter    ${request}    linkD
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:15:13

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name    network-topology-model
    ${request}    Set Range String Filter    ${request}    linkA    linkB
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:1:4    link:1:3    link:1:2-1

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name    opendaylight-inventory-model
    ${request}    Set Range String Filter    ${request}    linkC    linkD
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:14:12    link:15:13

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name    network-topology-model
    ${script}    Set Variable    if (node.getValue().indexOf("linkA") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:1:3    link:1:2-2

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name    opendaylight-inventory-model
    ${script}    Set Variable    if (node.getValue().indexOf("linkA") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request    ${request}    network-topology:network-topology/topology/topo:1    ietf-network:network/topo:1
    Should Contain    ${resp.content}    <network-id>topo:1</network-id>
    Check Filtered Links In Network    ${resp.content}    link:11:12    link:14:12    link:15:13

*** Keywords ***
Check Filtered Links In Network
    [Arguments]    ${xml}    @{supp_link_ids}
    ${supp_link_count}    Get Length    ${supp_link_ids}
    Should Contain X Times    ${xml}    <link-id>    ${supp_link_count}
    Should Contain X Times    ${xml}    <link-ref>    ${supp_link_count}
    : FOR    ${supp_link_id}    IN    @{supp_link_ids}
    \    Should Contain X Times    ${xml}    <link-ref>${supp_link_id}</link-ref>    1

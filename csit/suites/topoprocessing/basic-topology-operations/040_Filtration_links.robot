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
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:metric
    ${request}    Set Range Number Filter    ${request}    11    13
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    3
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:4</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:3</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-1</link-ref>    1

Filtration Range Number Inventory Model
    [Documentation]    Test of range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:metric
    ${request}    Set Range Number Filter    ${request}    14    15
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:14:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1

Filtration Specific String Network Topology Model
    [Documentation]    Test of specific string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name
    ${request}    Set Specific String Filter    ${request}    linkA
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:4</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-1</link-ref>    1

Filtration Specific String Inventory Model
    [Documentation]    Test of specific string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_SPECIFIC_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name
    ${request}    Set Specific String Filter    ${request}    linkD
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1

Filtration Range String Network Topology Model
    [Documentation]    Test of range string type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name
    ${request}    Set Range String Filter    ${request}    linkA    linkB
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    3
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:4</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-1</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:3</link-ref>    1

Filtration Range String Inventory Model
    [Documentation]    Test of range string type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_STRING}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name
    ${request}    Set Range String Filter    ${request}    linkC    linkD
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:14:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1

Filtration Script Network Topology Model
    [Documentation]    Test of script type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name
    ${script}    Set Variable    if (node.getValue().indexOf("linkA") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:3</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-2</link-ref>    1

Filtration Script Inventory Model
    [Documentation]    Test of script type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_SCRIPT}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:name
    ${script}    Set Variable    if (node.getValue().indexOf("linkA") > -1 ) {filterOut.setResult(true);} else {filterOut.setResult(false);}
    ${request}    Set Script Filter    ${request}    javascript    ${script}
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Check Supporting Links in Links    ${resp.content}    3
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:11:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:14:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1

*** Keywords ***
Check Supporting Links in Links
    [Arguments]    ${content}    ${number_of_links}
    : FOR    ${index}    IN RANGE    1    ${number_of_links} + 1
    \    ${link}    Get Element    ${content}    xpath=.//link[${index}]
    \    ${link}    Element To String    ${link}
    \    Should Contain X Times    ${link}    <link-ref>    1

*** Settings ***
Documentation     Test suite to verify processing of removal requests on different models.
...               Before tests start, configurational files have to be rewriten to change listeners registration datastore type from CONFIG_API to OPERATIONAL_API.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Suite setup also installs features required for tested models and clears karaf logs for further synchronization. Tests themselves send configurational
...               xmls and verify output. Topology-id on the end of each url must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Teardown     Test Teardown With Underlay Topologies Refresh    network-topology:network-topology/topology/topo:1
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Variables ***
${OVERLAY_TOPO_URL}    ${TOPOLOGY_URL}/topo:1

*** Test Cases ***
Unification Node Removal NT
    [Documentation]    Test processing of node removal using unification operation on Network Topology model
    ${model}    Set Variable    network-topology-model
    #Create the original topology
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Target Field    ${request}    1    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <node-id>node:    8
    #Remove an underlay aggregated node, preserving the overlay node
    Delete Underlay Node    network-topo:1    bgp:3
    ${resp}    Wait Until Keyword Succeeds    10x    250ms    Basic Request Get And Test    ${OVERLAY_TOPO_URL}    <supporting-node>    9
    Check Aggregated Node in Topology    ${model}    ${resp.content}    2    bgp:4
    #Remove an underlay aggregated node, expecting removal of the overlay node
    Delete Underlay Node    network-topo:1    bgp:4
    Wait Until Keyword Succeeds    10x    250ms    Basic Request Get And Test    ${OVERLAY_TOPO_URL}    <supporting-node>    8

Unification Node Removal Inventory
    [Documentation]    Test processing of node removal using unification operation on Inventory model
    ${model}    Set Variable    opendaylight-inventory-model
    #Create the original topology
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    ${model}    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${request}    Insert Target Field    ${request}    1    flow-node-inventory:ip-address    0
    Send Basic Request And Test If Contain X Times    ${request}    ${OVERLAY_TOPO_URL}    <node-id>node:    7
    #Remove an underlay aggregated node, preserving the overlay node
    Delete Underlay Node    openflow-topo:2    of-node:6
    ${resp}    Wait Until Keyword Succeeds    10x    250ms    Basic Request Get And Test    ${OVERLAY_TOPO_URL}    <supporting-node>    9
    Check Aggregated Node in Topology    ${model}    ${resp.content}    2    of-node:1
    #Remove an underlay aggregated node, expecting removal of the overlay node
    Delete Underlay Node    openflow-topo:1    of-node:1
    Wait Until Keyword Succeeds    10x    250ms    Basic Request Get And Test    ${OVERLAY_TOPO_URL}    <supporting-node>    8

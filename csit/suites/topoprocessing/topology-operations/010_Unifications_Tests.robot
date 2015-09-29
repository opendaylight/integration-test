*** Settings ***
Documentation     Test suite to verify unification operation on different models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIGURATION to OPERATIONAL.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Tests themselves install feature required for specific model, clear karaf logs for futher synchronization, send configurational xmls and verify output.
...               Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Enviroment
Suite Teardown    Test Teardown
Library           RequestsLibrary
Library           SSHLibrary
Variables         ../../../variables/topoprocessing/Requests.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${CONFIGURATION_XML}    ../configuration.xml
${OPERATIONAL_XML}    ../operational.xml
${REMOTE_FILE}    ${WORKSPACE}/${BUNDLEFOLDER}/etc/opendaylight/karaf/80-topoprocessing-config.xml
${OPERATIONAL}    /restconf/operational
${CONFIGURATION}    /restconf/config

*** Test Cases ***
Unification on Network Topology
    [Documentation]    Test unification operation on Network Topology model
    Prepare New Feature Installation
    Install a Feature    odl-topoprocessing-network-topology odl-bgpcep-pcep-all    timeout=30
    Wait For Karaf Log    Registering Topology Request Listener
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/unif:1    data=${UNIFICATION_NT}
    Log    ${CONFIGURATION} ${TOPOLOGY_URL}/unif:1
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait For Karaf Log    Correlation configuration successfully read
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/und-topo:1    data=${UNDERLAY_TOPOLOGY_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Issue Command On Karaf Console    log:clear
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/und-topo:2    data=${UNDERLAY_TOPOLOGY_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait For Karaf Log    Transaction successfully written
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL}/network-topology:network-topology
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    <topology-id>unif:1</topology-id>
    Should Contain X Times    ${resp.content}    <node-id>node:    9
    Should Match Regexp    ${resp.content}    <node><node-id>node:.?</node-id>((<supporting-node><node-ref>pcep:5</node-ref><topology-ref>und-topo:1</topology-ref></supporting-node>)|(<supporting-node><node-ref>pcep:10</node-ref><topology-ref>und-topo:2</topology-ref></supporting-node>)){2}</node>

*** Keywords ***
Setup Enviroment
    [Documentation]    Setup karaf enviroment for following tests
    Open Connection    ${CONTROLLER}
    Flexible Controller Login
    Put File    ${CONFIGURATION_XML}    ${REMOTE_FILE}
    Close Connection
    Issue Command On Karaf Console    log:set TRACE org.opendaylight.topoprocessing
    Install a Feature    odl-topoprocessing-framework odl-restconf-noauth    timeout=30
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${SEND_ACCEPT_XML_HEADERS}

Test Teardown
    [Documentation]    Revert startup changes
    Open Connection    ${CONTROLLER}
    Flexible Controller Login
    Put File    ${OPERATIONAL_XML}    ${REMOTE_FILE}
    Close Connection
    Delete All Sessions

Wait For Karaf Log
    [Arguments]    ${message}
    [Documentation]    Read karaf logs until message appear
    Open Connection    ${CONTROLLER}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=60
    Flexible SSH Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    log:tail
    Read Until    ${message}
    Close Connection

Prepare New Feature Installation
    [Documentation]    Clears karaf logs and CONFIGURATION datastore
    ${resp}    RequestsLibrary.Delete    session    ${CONFIGURATION}/network-topology:network-topology
    Issue Command On Karaf Console    log:clear

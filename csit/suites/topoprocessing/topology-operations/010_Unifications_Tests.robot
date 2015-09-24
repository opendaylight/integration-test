*** Settings ***
Documentation     Test suite to verify unification operation on different models
Suite Setup       Setup Enviroment
Suite Teardown    Test Teardown
Library           RequestsLibrary
Library           OperatingSystem
Library           SSHLibrary
Variables         ../../../variables/topoprocessing/Requests.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${CONFIGURATION_XML}    ../configuration.xml
${OPERATIONAL_XML}    ../operational.xml
${REMOTE_FILE}    /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/80-topoprocessing-config.xml
${OPERATIONAL}    /restconf/operational
${CONFIGURATION}    /restconf/config
${TOPOLOGY_URL}    /network-topology:network-topology/topology

*** Test Cases ***
Unification on Network Topology
    [Documentation]    Test unification operation on Network Topology model
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}${TOPOLOGY_URL}/unif:1    data=${UNIFICATION_NT}
    Log    ${CONFIGURATION} ${TOPOLOGY_URL}/unif:1
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait For Karaf Log    Correlation configuration successfully read
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}${TOPOLOGY_URL}/und-topo:1    data=${UNDERLAY_TOPOLOGY_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}${TOPOLOGY_URL}/und-topo:2    data=${UNDERLAY_TOPOLOGY_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL}/network-topology:network-topology
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    unif:1

*** Keywords ***
Setup Enviroment
    [Documentation]    Setup karaf enviroment for following tests
    Open Connection    ${CONTROLLER}
    Login    ${CONTROLLER_USER}    ${CONTROLLER_PASSWORD}
    Put File    ${CONFIGURATION_XML}    ${REMOTE_FILE}
    Close Connection
    Install a Feature    odl-topoprocessing-framework odl-restconf-noauth odl-topoprocessing-network-topology odl-bgpcep-pcep-all    timeout=30
    Wait For Karaf Log    Registering Topology Request Listener
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

Test Teardown
    [Documentation]    Revert startup changes
    Open Connection    ${CONTROLLER}
    Login    ${CONTROLLER_USER}    ${CONTROLLER_PASSWORD}
    Put File    ${OPERATIONAL_XML}    ${REMOTE_FILE}
    Close Connection
    Delete All Sessions

Wait For Karaf Log
    [Arguments]    ${message}
    [Documentation]    Read karaf logs until message appear
    Open Connection    ${CONTROLLER}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=60
    Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    log:set TRACE org.opendaylight.topoprocessing
    Write    log:tail
    Read Until    ${message}
    Close Connection

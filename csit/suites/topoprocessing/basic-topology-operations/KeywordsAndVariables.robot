*** Variables ***
${CONFIGURATION_XML}    ${CURDIR}/../configuration.xml
${OPERATIONAL_XML}    ${CURDIR}/../operational.xml
${REMOTE_FILE}    ${WORKSPACE}/${BUNDLEFOLDER}/etc/opendaylight/karaf/80-topoprocessing-config.xml
${OPERATIONAL}    /restconf/operational
${CONFIGURATION}    /restconf/config

*** Keywords ***
Basic Aggregation
    [Arguments]    ${request}    ${overlay_topology_url}
    [Documentation]    Test basic aggregation
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${overlay_topology_url}    data=${request}
    Log    ${CONFIGURATION}/${overlay_topology_url}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait For Karaf Log    Correlation configuration successfully read
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait For Karaf Log    Transaction successfully written
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL}/${overlay_topology_url}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    [Return]    ${resp}

Setup Environment
    [Documentation]    Setup karaf enviroment for following tests
    Log    ---- Setup Environment ----
    Open Connection    ${CONTROLLER}
    Flexible Controller Login
    Put File    ${CONFIGURATION_XML}    ${REMOTE_FILE}
    Close Connection
    Issue Command On Karaf Console    log:set DEBUG org.opendaylight.topoprocessing
    Install a Feature    odl-restconf-noauth    timeout=30
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${SEND_ACCEPT_XML_HEADERS}
    Prepare New Feature Installation
    Install a Feature    odl-topoprocessing-network-topology odl-topoprocessing-inventory odl-bgpcep-pcep-all odl-ovsdb-southbound-api    timeout=30
    #Wait For Karaf Log    Registering Topology Request Listener    300
    Insert Underlay topologies

Clean Environment
    [Documentation]    Revert startup changes
    Log    ---- Clean Environment ----
    Uninstall a Feature    odl-topoprocessing-framework odl-topoprocessing-network-topology odl-topoprocessing-inventory    timeout=30
    Open Connection    ${CONTROLLER}
    Flexible Controller Login
    #Put File    ${OPERATIONAL_XML}    ${REMOTE_FILE}
    Close Connection
    Delete All Sessions

Test Teardown
    [Arguments]    ${overlay_topology_url}
    [Documentation]    Delete overlay topologies from datastore
    Log    ---- Test Teardown ----
    Log    Deleting overlay topology from ${CONFIGURATION}/${overlay_topology_url}
    ${resp}    RequestsLibrary.Delete    session    ${CONFIGURATION}/${overlay_topology_url}
    Should Be Equal As Strings    ${resp.status_code}    200

Wait For Karaf Log
    [Arguments]    ${message}    ${timeout}=60
    [Documentation]    Read karaf logs until message appear
    Open Connection    ${CONTROLLER}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Flexible SSH Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    log:tail
    Read Until    ${message}
    Close Connection

Prepare New Feature Installation
    [Documentation]    Clears karaf logs and CONFIGURATION datastore
    ${resp}    RequestsLibrary.Delete    session    ${CONFIGURATION}/network-topology:network-topology
    ${resp}    RequestsLibrary.Delete    session    ${CONFIGURATION}/opendaylight-inventory:nodes
    Issue Command On Karaf Console    log:clear

Insert Underlay Topologies
    [Documentation]    Insert underlay topologies used by following tests
    Log    Inserting underlay topologies
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/und-topo:1    data=${UNDERLAY_TOPOLOGY_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Issue Command On Karaf Console    log:clear
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/und-topo:2    data=${UNDERLAY_TOPOLOGY_2}
    Log    ${resp.content}

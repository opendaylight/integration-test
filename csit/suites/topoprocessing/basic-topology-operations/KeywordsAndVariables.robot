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
    Install a Feature    odl-topoprocessing-framework odl-topoprocessing-network-topology odl-topoprocessing-inventory odl-bgpcep-pcep-all odl-openflowplugin-nsf-model-li    timeout=30
    #Wait For Karaf Log    Registering Topology Request Listener    300
    Insert Underlay topologies

Clean Environment
    [Documentation]    Revert startup changes
    Log    ---- Clean Environment ----
    Uninstall a Feature    odl-topoprocessing-framework odl-topoprocessing-network-topology odl-topoprocessing-inventory    timeout=30
    Open Connection    ${CONTROLLER}
    Flexible Controller Login
    Put File    ${OPERATIONAL_XML}    ${REMOTE_FILE}
    Close Connection
    Delete All Sessions

Test Teardown
    [Documentation]    Delete overlay topologies from datastore
    Log    ---- Test Teardown ----
    Log    Deleting overlay topology from ${CONFIGURATION}/network-topology:network-topology/topology/topo:1
    ${resp}    RequestsLibrary.Delete    session    ${CONFIGURATION}/network-topology:network-topology/topology/topo:1
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
    # Network underlay topology 1
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/network-topo:1    data=${NETWORK_UNDERLAY_TOPOLOGY_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Network underlay topology 2
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/network-topo:2    data=${NETWORK_UNDERLAY_TOPOLOGY_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay nodes
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/opendaylight-inventory:nodes    data=${OPENFLOW_UNDERLAY_NODES}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topology 1
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/openflow-topo:1    data=${OPENFLOW_UNDERLAY_TOPOLOGY_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topology 2
    ${resp}    RequestsLibrary.Put    session    ${CONFIGURATION}/${TOPOLOGY_URL}/openflow-topo:2    data=${OPENFLOW_UNDERLAY_TOPOLOGY_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Issue Command On Karaf Console    log:clear
    Log    ${resp.content}

Prepare Unification Inside Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${target-field}    ${underlay_topo1}
    [Documentation]    Prepare topology request for unification inside from template
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text    ${request_template}    aggregation-only    xpath=.//correlations/correlation/type
    ${request_template}    Set Element Text    ${request_template}    ${correlation_item}    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text    ${request_template}    unification    xpath=.//correlation/aggregation/aggregation-type
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/aggregation/mapping[1]/input-model
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo1}    xpath=.//correlation/aggregation/mapping[1]/underlay-topology
    ${request_template}    Set Element Text    ${request_template}    ${target-field}    xpath=.//correlation/aggregation/mapping[1]/target-field
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Prepare Unification Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${target-field}    ${underlay_topo1}    ${underlay_topo2}
    [Documentation]    Prepare topology request for unification on two topologies from template
    ${request_template}    Prepare Unification Inside Topology Request    ${request_template}    ${model}    ${correlation_item}    ${target-field}    ${underlay_topo1}
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo2}    xpath=.//correlation/aggregation/mapping[2]/underlay-topology
    ${request_template}    Set Element Text    ${request_template}    ${target-field}    xpath=.//correlation/aggregation/mapping[2]/target-field
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/aggregation/mapping[2]/input-model
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

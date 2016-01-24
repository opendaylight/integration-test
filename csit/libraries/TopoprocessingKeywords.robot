*** Settings ***
Variables         ../variables/Variables.py
Variables         ../variables/topoprocessing/Topologies.py
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Resource          KarafKeywords.robot
Resource          Utils.robot

*** Variables ***
${CONFIGURATION_XML}    ${CURDIR}/../suites/topoprocessing/configuration.xml
${OPERATIONAL_XML}    ${CURDIR}/../suites/topoprocessing/operational.xml
${REMOTE_FILE}    ${WORKSPACE}/${BUNDLEFOLDER}/etc/opendaylight/karaf/80-topoprocessing-config.xml

*** Keywords ***
Send Basic Request
    [Arguments]    ${request}    ${overlay_topology_url}
    [Documentation]    Test basic aggregation
    ${resp}    Put Request    session    ${CONFIG_API}/${overlay_topology_url}    data=${request}
    Log    ${CONFIG_API}/${overlay_topology_url}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait For Karaf Log    Correlation configuration successfully read
    Wait For Karaf Log    Transaction successfully written
    ${resp}    Get Request    session    ${OPERATIONAL_API}/${overlay_topology_url}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    [Return]    ${resp}

Setup Environment
    [Documentation]    Setup karaf enviroment for following tests
    Log    ---- Setup Environment ----
    Open Connection    ${ODL_SYSTEM_IP}
    Flexible Controller Login
    Put File    ${CONFIGURATION_XML}    ${REMOTE_FILE}
    Close Connection
    Issue Command On Karaf Console    log:set DEBUG org.opendaylight.topoprocessing
    Install a Feature    odl-restconf-noauth    timeout=30
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${SEND_ACCEPT_XML_HEADERS}
    ${features}    Get Installed Features
    ${lines}    Get Lines Containing String    ${features}    odl-topoprocessing-framework
    ${length}    Get Length    ${lines}
    Install a Feature    odl-openflowplugin-nsf-model-li odl-topoprocessing-framework odl-topoprocessing-network-topology odl-topoprocessing-inventory odl-mdsal-models odl-ovsdb-southbound-impl    timeout=120
    Run Keyword If    ${length} == 0    Wait For Karaf Log    Registering Topology Request Listener    60
    Prepare New Feature Installation
    Insert Underlay topologies

Clean Environment
    [Documentation]    Revert startup changes
    Log    ---- Clean Environment ----
    Open Connection    ${ODL_SYSTEM_IP}
    Flexible Controller Login
    Put File    ${OPERATIONAL_XML}    ${REMOTE_FILE}
    Close Connection
    Delete All Sessions

Test Teardown
    [Arguments]    ${overlay_topology}
    [Documentation]    Delete overlay topologies from datastore
    Log    ---- Test Teardown ----
    Log    Deleting overlay topology from ${CONFIG_API}/${overlay_topology}
    ${resp}    Delete Request    session    ${CONFIG_API}/${overlay_topology}
    Should Be Equal As Strings    ${resp.status_code}    200

Prepare New Feature Installation
    [Documentation]    Clears karaf logs and CONFIGURATION datastore
    ${resp}    Delete Request    session    ${CONFIG_API}/network-topology:network-topology
    ${resp}    Delete Request    session    ${CONFIG_API}/opendaylight-inventory:nodes
    Issue Command On Karaf Console    log:clear

Insert Underlay Topologies
    [Documentation]    Insert underlay topologies used by following tests
    Log    Inserting underlay topologies
    # Network underlay topology 1
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:1    data=${NETWORK_UNDERLAY_TOPOLOGY_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Network underlay topology 2
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:2    data=${NETWORK_UNDERLAY_TOPOLOGY_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay nodes
    ${resp}    Put Request    session    ${CONFIG_API}/opendaylight-inventory:nodes    data=${OPENFLOW_UNDERLAY_NODES}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topology 1
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:1    data=${OPENFLOW_UNDERLAY_TOPOLOGY_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topology 2
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:2    data=${OPENFLOW_UNDERLAY_TOPOLOGY_2}
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

Get Installed Features
    [Documentation]    Returns list of installed features as String
    Open Connection    ${ODL_SYSTEM_IP}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=5
    Flexible SSH Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    feature:list -i
    ${features}    Read until prompt
    Close Connection
    Log    Installed features:
    Log    ${features}
    [Return]    ${features}

Insert Scripting into Request
    [Arguments]    ${request}    ${language}    ${script}
    [Documentation]    Insert Scripting into Request under aggregation node
    ${request}    Add Element    ${request}    ${SCRIPTING}    xpath=.//correlation/aggregation
    ${request}    Set Element Text    ${request}    ${script}    xpath=.//correlation/aggregation/scripting/script
    ${request}    Set Element Text    ${request}    ${language}    xpath=.//correlation/aggregation/scripting/language
    ${request}    Element to String    ${request}
    [Return]    ${request}

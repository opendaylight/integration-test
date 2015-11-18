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
    Open Connection    ${CONTROLLER}
    Flexible Controller Login
    Put File    ${CONFIGURATION_XML}    ${REMOTE_FILE}
    Close Connection
    Issue Command On Karaf Console    log:set DEBUG org.opendaylight.topoprocessing
    Install a Feature    odl-restconf-noauth    timeout=30
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${SEND_ACCEPT_XML_HEADERS}
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
    Open Connection    ${CONTROLLER}
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

Get Installed Features
    [Documentation]    Returns list of installed features as String
    Open Connection    ${CONTROLLER}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=5
    Flexible SSH Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    feature:list -i
    ${features}    Read until prompt
    Close Connection
    Log    Installed features:
    Log    ${features}
    [Return]    ${features}

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
    # Network underlay topology 3
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:3    data=${NETWORK_UNDERLAY_TOPOLOGY_3}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Network underlay topology 4
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:4    data=${NETWORK_UNDERLAY_TOPOLOGY_4}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Network underlay topology 5
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:5    data=${NETWORK_UNDERLAY_TOPOLOGY_5}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Network underlay topology 6
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:6    data=${NETWORK_UNDERLAY_TOPOLOGY_6}
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
    # Openflow underlay topology 3
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:3    data=${OPENFLOW_UNDERLAY_TOPOLOGY_3}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topology 4
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:4    data=${OPENFLOW_UNDERLAY_TOPOLOGY_4}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topology 5
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:5    data=${OPENFLOW_UNDERLAY_TOPOLOGY_5}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topology 5
    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:6    data=${OPENFLOW_UNDERLAY_TOPOLOGY_6}
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

Prepare Unification Filtration Topology Request
    [Arguments]    ${request_template}    ${model}    ${target-field}    ${underlay_topo2}
    [Documentation]    Prepare topology request for unification on two topologies from template
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo2}    xpath=.//correlation/aggregation/mapping[2]/underlay-topology
    ${request_template}    Set Element Text    ${request_template}    ${target-field}    xpath=.//correlation/aggregation/mapping[2]/target-field
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/aggregation/mapping[2]/input-model
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Prepare Unification Filtration Inside Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${target-field}    ${underlay_topo}
    [Documentation]    Prepare topology request for unification filtration inside from template
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text    ${request_template}    filtration-aggregation    xpath=.//correlations/correlation/type
    ${request_template}    Set Element Text    ${request_template}    ${correlation_item}    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text    ${request_template}    unification    xpath=.//correlation/aggregation/aggregation-type
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/aggregation/mapping[1]/input-model
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo}    xpath=.//correlation/aggregation/mapping[1]/underlay-topology
    ${request_template}    Set Element Text    ${request_template}    ${target-field}    xpath=.//correlation/aggregation/mapping[1]/target-field
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo}    xpath=.//correlation/filtration/underlay-topology
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Prepare Filtration Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo}
    [Documentation]    Prepare topology request for filtration from template
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text    ${request_template}    ${correlation_item}    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo}    xpath=.//correlation/filtration/underlay-topology
    [Return]    ${request_template}

Insert Filter
    [Arguments]    ${request_template}    ${filter_template}    ${target_field}
    [Documentation]    Add filter to filtration
    ${request_template}    Add Element    ${request_template}    ${filter_template}    xpath=.//correlation/filtration
    ${model}    Get Element Text    ${request_template}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/filtration/filter/input-model
    ${request_template}    Set Element Text    ${request_template}    ${target_field}    xpath=.//correlation/filtration/filter/target-field
    [Return]    ${request_template}

Set IPV4 Filter
    [Arguments]    ${request_template}    ${ip_address}
    [Documentation]    Set filter ipv4 address
    ${request_template}    Set Element Text    ${request_template}    ${ip_address}    xpath=.//correlation/filtration/filter/ipv4-address-filter/ipv4-address
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Set Range Number Filter
    [Arguments]    ${request_template}    ${min_number}    ${max_number}
    [Documentation]    Set filter minimum and maximum number values
    ${request_template}    Set Element Text    ${request_template}    ${min_number}    xpath=.//correlation/filtration/filter/range-number-filter/min-number-value
    ${request_template}    Set Element Text    ${request_template}    ${max_number}    xpath=.//correlation/filtration/filter/range-number-filter/max-number-value
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Set Range String Filter
    [Arguments]    ${request_template}    ${min_value}    ${max_value}
    [Documentation]    Set filter minimum and maximum string values
    ${request_template}    Set Element Text    ${request_template}    ${min_value}    xpath=.//correlation/filtration/filter/range-string-filter/min-string-value
    ${request_template}    Set Element Text    ${request_template}    ${max_value}    xpath=.//correlation/filtration/filter/range-string-filter/max-string-value
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Set Specific Number Filter
    [Arguments]    ${request_template}    ${number}
    [Documentation]    Set filter number value
    ${request_template}    Set Element Text    ${request_template}    ${number}    xpath=.//correlation/filtration/filter/specific-number-filter/specific-number
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Set Specific String Filter
    [Arguments]    ${request_template}    ${string_value}
    [Documentation]    Set filter string value
    ${request_template}    Set Element Text    ${request_template}    ${string_value}    xpath=.//correlation/filtration/filter/specific-string-filter/specific-string
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Set IPV6 Filter
    [Arguments]    ${request_template}    ${ip_address}
    [Documentation]    Set filter ipv6 address
    ${request_template}    Set Element Text    ${request_template}    ${ip_address}    xpath=.//correlation/filtration/filter/ipv6-address-filter/ipv6-address
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Set Script Filter
    [Arguments]    ${request_template}    ${script_language}    ${script}
    [Documentation]    Set filter script
    ${request_template}    Set Element Text    ${request_template}    ${script_language}    xpath=.//correlation/filtration/filter/script-filter/scripting/language
    ${request_template}    Set Element Text    ${request_template}    ${script}    xpath=.//correlation/filtration/filter/script-filter/scripting/script
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Insert Link Computation Inside
    [Arguments]    ${request_template}    ${link_computation_template}    ${input_model}    ${underlay_topology}
    [Documentation]    Add link computation to request
    ${request_template}    Add Element    ${request_template}    ${link_computation_template}    xpath=.
    ${request_template}    Set Element Text    ${request_template}    ${input_model}    xpath=.//link-computation/node-info/input-model
    ${request_template}    Set Element Text    ${request_template}    ${input_model}    xpath=.//link-computation/link-info/input-model
    ${request_template}    Set Element Text    ${request_template}    ${input_model}    xpath=.//link-computation/output-model
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topology}    xpath=.//link-computation/link-info/link-topology
    ${request_template}    Set Element Attribute    ${request_template}    xmlns:n    urn:opendaylight:topology:correlation    xpath=./link-computation
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Insert Link Computation
    [Arguments]    ${request_template}    ${link_computation_template}    ${input_model}    ${underlay_topology_1}    ${underlay_topology_2}
    [Documentation]    Add link computation to request
    ${request_template}    Add Element    ${request_template}    ${link_computation_template}    xpath=.
    ${request_template}    Set Element Text    ${request_template}    ${input_model}    xpath=.//link-computation/node-info/input-model
    ${request_template}    Set Element Text    ${request_template}    ${input_model}    xpath=.//link-computation/link-info[1]/input-model
    ${request_template}    Set Element Text    ${request_template}    ${input_model}    xpath=.//link-computation/link-info[2]/input-model
    ${request_template}    Set Element Text    ${request_template}    ${input_model}    xpath=.//link-computation/output-model
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topology_1}    xpath=.//link-computation/link-info[1]/link-topology
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topology_2}    xpath=.//link-computation/link-info[2]/link-topology
    ${request_template}    Set Element Attribute    ${request_template}    xmlns:n    urn:opendaylight:topology:correlation    xpath=./link-computation
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Insert Scripting into Request
    [Arguments]    ${request}    ${language}    ${script}
    [Documentation]    Insert Scripting into Request under aggregation node
    ${request}    Add Element    ${request}    ${SCRIPTING}    xpath=.//correlation/aggregation
    ${request}    Set Element Text    ${request}    ${script}    xpath=.//correlation/aggregation/scripting/script
    ${request}    Set Element Text    ${request}    ${language}    xpath=.//correlation/aggregation/scripting/language
    ${request}    Element to String    ${request}
    [Return]    ${request}

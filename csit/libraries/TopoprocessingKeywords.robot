*** Settings ***
Variables       ../variables/Variables.py
Variables       ../variables/topoprocessing/Topologies.py
Variables       ../variables/topoprocessing/TopologyRequests.py
Library         RequestsLibrary
Library         SSHLibrary
Library         XML
Resource        CompareStream.robot
Resource        KarafKeywords.robot
Resource        SetupUtils.robot
Resource        Utils.robot


*** Variables ***
${CONFIGURATION_XML}    ${CURDIR}/../suites/topoprocessing/configuration.xml
${OPERATIONAL_XML}      ${CURDIR}/../suites/topoprocessing/operational.xml
${CONFIGURATION_CFG}    ${CURDIR}/../suites/topoprocessing/configuration.cfg
${OPERATIONAL_CFG}      ${CURDIR}/../suites/topoprocessing/operational.cfg
${REMOTE_XML_FILE}      ${WORKSPACE}/${BUNDLEFOLDER}/etc/opendaylight/karaf/80-topoprocessing-config.xml
${REMOTE_CFG_FILE}      ${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.topoprocessing.cfg
${OUTPUT_TOPO_NAME}     topo:1
${OVERLAY_TOPO_URL}     ${TOPOLOGY_URL}/${OUTPUT_TOPO_NAME}


*** Keywords ***
Basic Request Put
    [Documentation]    Send a simple HTTP PUT request to Configurational datastore
    [Arguments]    ${request}    ${overlay_topology_url}
    ${resp}    Put Request    session    ${CONFIG_API}/${overlay_topology_url}    data=${request}
    Log    ${CONFIG_API}/${overlay_topology_url}
    Should Match    "${resp.status_code}"    "20?"
    Wait For Karaf Log    Correlation configuration successfully read
    Wait For Karaf Log    Transaction successfully written

Basic Request Get
    [Documentation]    Send a simple HTTP GET request to a given URL
    [Arguments]    ${overlay_topology_url}
    ${resp}    Get On Session    session    ${OPERATIONAL_API}/${overlay_topology_url}    expected_status=200
    RETURN    ${resp}

Send Basic Delete Request
    [Documentation]    Sends a HTTP/DELETE request to a given URL
    [Arguments]    ${url}
    ${resp}    Delete Request    session    ${CONFIG_API}/${url}
    Log    Deleting ${CONFIG_API}/${url}
    RETURN    ${resp}

Delete Underlay Node
    [Documentation]    Deletes a node from an underlay topology
    [Arguments]    ${topology-id}    ${node-id}
    ${resp}    Send Basic Delete Request    ${TOPOLOGY_URL}/${topology-id}/node/${node-id}
    RETURN    ${resp}

Delete Underlay Termination Point
    [Documentation]    Deletes a termination point from an underlay topology
    [Arguments]    ${topology-id}    ${node-id}    ${tp-id}
    ${resp}    Send Basic Delete Request    ${TOPOLOGY_URL}/${topology-id}/node/${node-id}/termination-point/${tp-id}
    RETURN    ${resp}

Delete Underlay Link
    [Documentation]    Deletes a link from an underlay topology
    [Arguments]    ${topology-id}    ${link-id}
    ${resp}    Send Basic Delete Request    ${TOPOLOGY_URL}/${topology-id}/link/${link-id}
    RETURN    ${resp}

Setup Environment
    [Documentation]    Setup karaf enviroment for following tests
    Log    ---- Setup Environment ----
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Open Connection    ${ODL_SYSTEM_IP}
    Flexible Controller Login
    Put File    ${CONFIGURATION_CFG}    ${REMOTE_CFG_FILE}
    Close Connection
    Wait Until Keyword Succeeds
    ...    2x
    ...    2s
    ...    Issue Command On Karaf Console
    ...    log:set DEBUG org.opendaylight.topoprocessing
    Create Session
    ...    session
    ...    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${SEND_ACCEPT_XML_HEADERS}
    Prepare New Feature Installation
    Insert Underlay topologies

Install Features
    [Documentation]    Install features according to tested distribution
    [Arguments]    ${features}    ${timeout}=180
    Install Features for Other Distributions    ${features}    ${timeout}

Install Features for Beryllium Distribution
    [Documentation]    Will wait for features to install only once per run
    [Arguments]    ${features}    ${timeout}
    Install a Feature    ${features}    timeout=${timeout}
    Set Global Variable If It Does Not Exist    \${WAIT_FOR_FEATURES_TO_INSTALL}    ${TRUE}
    IF    ${WAIT_FOR_FEATURES_TO_INSTALL}
        Wait For Karaf Log    Registering Topology Request Listener    ${timeout}
        Set Global Variable    \${WAIT_FOR_FEATURES_TO_INSTALL}    ${FALSE}
    END

Install Features for Other Distributions
    [Documentation]    Will wait for features to install only if no topoprocessing feature was installed
    [Arguments]    ${features}    ${timeout}
    ${installed_features}    Issue Command On Karaf Console    feature:list -i
    ${lines}    Get Lines Containing String    ${installed_features}    odl-topoprocessing-framework
    ${length}    Get Length    ${lines}
    Install a Feature    ${features}    timeout=${timeout}
    IF    ${length} == 0
        Wait For Karaf Log    Registering Topology Request Listener    ${timeout}
    END

Clean Environment
    [Documentation]    Revert startup changes
    Log    ---- Clean Environment ----
    Open Connection    ${ODL_SYSTEM_IP}
    Flexible Controller Login
    Put File    ${OPERATIONAL_CFG}    ${REMOTE_CFG_FILE}
    Close Connection
    Delete All Sessions

Delete Overlay Topology
    [Documentation]    Delete overlay topologies from datastore
    Run Keyword If Test Failed    Print Output Topo
    Log    ---- Test Teardown ----
    Log    Deleting overlay topology from ${CONFIG_API}/${OVERLAY_TOPO_URL}
    ${resp}    Delete Request    session    ${CONFIG_API}/${OVERLAY_TOPO_URL}
    Should Be Equal As Strings    ${resp.status_code}    200

Print Output Topo
    [Documentation]    Waits a while to allow any hanging transactions to finnish and then logs the output topology
    Log    ---- Output Topo Dump After Cooldown----
    Sleep    2s
    ${resp}    Wait Until Keyword Succeeds    5x    250ms    Basic Request Get    ${OVERLAY_TOPO_URL}
    Log    ${resp.text}

Refresh Underlay Topologies And Delete Overlay Topology
    [Documentation]    Deletes given overlay topology from datastore and overwrites the underlaying ones with initial topologies
    Delete Overlay Topology
    Insert Underlay Topologies

Prepare New Feature Installation
    [Documentation]    Clears karaf logs and CONFIGURATION datastore
    ${resp}    Delete Request    session    ${CONFIG_API}/network-topology:network-topology
    ${resp}    Delete Request    session    ${CONFIG_API}/opendaylight-inventory:nodes
    Issue Command On Karaf Console    log:clear

Insert Underlay Topologies
    [Documentation]    Insert underlay topologies used by following tests
    Log    Inserting underlay topologies
    # Network underlay topologies
    FOR    ${index}    IN RANGE    1    7
        ${resp}    Put Request
        ...    session
        ...    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:${index}
        ...    data=${NETWORK_UNDERLAY_TOPOLOGY_${index}}
        Log    ${resp.text}
        Should Match    "${resp.status_code}"    "20?"
        # Openflow underlay nodes
    END
    ${resp}    Put Request    session    ${CONFIG_API}/opendaylight-inventory:nodes    data=${OPENFLOW_UNDERLAY_NODES}
    Log    ${resp.text}
    Should Match    "${resp.status_code}"    "20?"
    # Openflow underlay topologies
    FOR    ${index}    IN RANGE    1    7
        ${resp}    Put Request
        ...    session
        ...    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:${index}
        ...    data=${OPENFLOW_UNDERLAY_TOPOLOGY_${index}}
        Log    ${resp.text}
        Should Match    "${resp.status_code}"    "20?"
    END
    Issue Command On Karaf Console    log:clear
    Log    ${resp.text}

Prepare Unification Inside Topology Request
    [Documentation]    Prepare topology request for unification inside from template
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo1}
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    aggregation-only
    ...    xpath=.//correlations/correlation/type
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${correlation_item}
    ...    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    unification
    ...    xpath=.//correlation/aggregation/aggregation-type
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${model}
    ...    xpath=.//correlation/aggregation/mapping[1]/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topo1}
    ...    xpath=.//correlation/aggregation/mapping[1]/underlay-topology
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Prepare Unification Topology Request
    [Documentation]    Prepare topology request for unification on two topologies from template
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo1}    ${underlay_topo2}
    ${request_template}    Prepare Unification Inside Topology Request
    ...    ${request_template}
    ...    ${model}
    ...    ${correlation_item}
    ...    ${underlay_topo1}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topo2}
    ...    xpath=.//correlation/aggregation/mapping[2]/underlay-topology
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${model}
    ...    xpath=.//correlation/aggregation/mapping[2]/input-model
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Prepare Unification Filtration Topology Request
    [Documentation]    Prepare topology request for unification on two topologies from template
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${target_field1}    ${underlay_topo1}    ${target_field2}
    ...    ${underlay_topo2}
    ${request_template}    Prepare Unification Filtration Inside Topology Request
    ...    ${request_template}
    ...    ${model}
    ...    ${correlation_item}
    ...    ${target_field1}
    ...    ${underlay_topo1}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topo2}
    ...    xpath=.//correlation/aggregation/mapping[2]/underlay-topology
    Insert Target Field    ${request_template}    2    ${target_field2}    1
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${model}
    ...    xpath=.//correlation/aggregation/mapping[2]/input-model
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Prepare Unification Filtration Inside Topology Request
    [Documentation]    Prepare topology request for unification filtration inside from template
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${target-field}    ${underlay_topo}
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    filtration-aggregation
    ...    xpath=.//correlations/correlation/type
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${correlation_item}
    ...    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    unification
    ...    xpath=.//correlation/aggregation/aggregation-type
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${model}
    ...    xpath=.//correlation/aggregation/mapping[1]/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topo}
    ...    xpath=.//correlation/aggregation/mapping[1]/underlay-topology
    Insert Target Field    ${request_template}    1    ${target-field}    1
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topo}
    ...    xpath=.//correlation/filtration/underlay-topology
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Insert Apply Filters
    [Arguments]    ${request_template}    ${mapping}    ${filter_id}
    ${request_template}    Add Element
    ...    ${request_template}
    ...    ${APPLY_FILTERS}
    ...    xpath=.//correlation/aggregation/mapping[${mapping}]
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${filter_id}
    ...    xpath=.//correlation/aggregation/mapping[${mapping}]/apply-filters
    RETURN    ${request_template}

Prepare Filtration Topology Request
    [Documentation]    Prepare topology request for filtration from template
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo}
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${correlation_item}
    ...    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topo}
    ...    xpath=.//correlation/filtration/underlay-topology
    RETURN    ${request_template}

Insert Target Field
    [Documentation]    Add target field to request
    [Arguments]    ${request_template}    ${mapping_index}    ${target_field_path}    ${matching_key}
    ${target_field_template}    Set Element Text
    ...    ${TARGET_FIELD}
    ...    ${target_field_path}
    ...    xpath=.//target-field-path
    ${target_field_template}    Set Element Text
    ...    ${target_field_template}
    ...    ${matching_key}
    ...    xpath=.//matching-key
    ${request_template}    Add Element
    ...    ${request_template}
    ...    ${target_field_template}
    ...    xpath=.//correlation/aggregation/mapping[${mapping_index}]
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Insert Filter
    [Documentation]    Add filter to filtration
    [Arguments]    ${request_template}    ${filter_template}    ${target_field}
    ${request_template}    Add Element    ${request_template}    ${filter_template}    xpath=.//correlation/filtration
    ${model}    Get Element Text    ${request_template}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${model}
    ...    xpath=.//correlation/filtration/filter/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${target_field}
    ...    xpath=.//correlation/filtration/filter/target-field
    RETURN    ${request_template}

Insert Filter With ID
    [Documentation]    Add filter to filtration with specified id
    [Arguments]    ${request_template}    ${filter_template}    ${target_field}    ${filter_id}
    ${request_template}    Insert Filter    ${request_template}    ${filter_template}    ${target_field}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${filter_id}
    ...    xpath=.//correlation/filtration/filter/filter-id
    RETURN    ${request_template}

Set IPV4 Filter
    [Documentation]    Set filter ipv4 address
    [Arguments]    ${request_template}    ${ip_address}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${ip_address}
    ...    xpath=.//correlation/filtration/filter/ipv4-address-filter/ipv4-address
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Set Range Number Filter
    [Documentation]    Set filter minimum and maximum number values
    [Arguments]    ${request_template}    ${min_number}    ${max_number}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${min_number}
    ...    xpath=.//correlation/filtration/filter/range-number-filter/min-number-value
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${max_number}
    ...    xpath=.//correlation/filtration/filter/range-number-filter/max-number-value
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Set Range String Filter
    [Documentation]    Set filter minimum and maximum string values
    [Arguments]    ${request_template}    ${min_value}    ${max_value}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${min_value}
    ...    xpath=.//correlation/filtration/filter/range-string-filter/min-string-value
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${max_value}
    ...    xpath=.//correlation/filtration/filter/range-string-filter/max-string-value
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Set Specific Number Filter
    [Documentation]    Set filter number value
    [Arguments]    ${request_template}    ${number}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${number}
    ...    xpath=.//correlation/filtration/filter/specific-number-filter/specific-number
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Set Specific String Filter
    [Documentation]    Set filter string value
    [Arguments]    ${request_template}    ${string_value}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${string_value}
    ...    xpath=.//correlation/filtration/filter/specific-string-filter/specific-string
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Set IPV6 Filter
    [Documentation]    Set filter ipv6 address
    [Arguments]    ${request_template}    ${ip_address}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${ip_address}
    ...    xpath=.//correlation/filtration/filter/ipv6-address-filter/ipv6-address
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Set Script Filter
    [Documentation]    Set filter script
    [Arguments]    ${request_template}    ${script_language}    ${script}
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${script_language}
    ...    xpath=.//correlation/filtration/filter/script-filter/scripting/language
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${script}
    ...    xpath=.//correlation/filtration/filter/script-filter/scripting/script
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Insert Link Computation Inside
    [Documentation]    Add link computation to request
    [Arguments]    ${request_template}    ${link_computation_template}    ${input_model}    ${underlay_topology}
    ${request_template}    Add Element    ${request_template}    ${link_computation_template}    xpath=.
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${input_model}
    ...    xpath=.//link-computation/node-info/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${input_model}
    ...    xpath=.//link-computation/link-info/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${input_model}
    ...    xpath=.//link-computation/output-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topology}
    ...    xpath=.//link-computation/link-info/link-topology
    ${request_template}    Set Element Attribute
    ...    ${request_template}
    ...    xmlns:n
    ...    urn:opendaylight:topology:correlation
    ...    xpath=./link-computation
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Insert Link Computation
    [Documentation]    Add link computation to request
    [Arguments]    ${request_template}    ${link_computation_template}    ${input_model}    ${underlay_topology_1}    ${underlay_topology_2}
    ${request_template}    Add Element    ${request_template}    ${link_computation_template}    xpath=.
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${input_model}
    ...    xpath=.//link-computation/node-info/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${input_model}
    ...    xpath=.//link-computation/link-info[1]/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${input_model}
    ...    xpath=.//link-computation/link-info[2]/input-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${input_model}
    ...    xpath=.//link-computation/output-model
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topology_1}
    ...    xpath=.//link-computation/link-info[1]/link-topology
    ${request_template}    Set Element Text
    ...    ${request_template}
    ...    ${underlay_topology_2}
    ...    xpath=.//link-computation/link-info[2]/link-topology
    ${request_template}    Set Element Attribute
    ...    ${request_template}
    ...    xmlns:n
    ...    urn:opendaylight:topology:correlation
    ...    xpath=./link-computation
    ${request_template}    Element to String    ${request_template}
    RETURN    ${request_template}

Insert Scripting into Request
    [Documentation]    Insert Scripting into Request under aggregation node
    [Arguments]    ${request}    ${language}    ${script}
    ${request}    Add Element    ${request}    ${SCRIPTING}    xpath=.//correlation/aggregation
    ${request}    Set Element Text    ${request}    ${script}    xpath=.//correlation/aggregation/scripting/script
    ${request}    Set Element Text    ${request}    ${language}    xpath=.//correlation/aggregation/scripting/language
    ${request}    Element to String    ${request}
    RETURN    ${request}

Create Isis Node
    [Documentation]    Create an isis node element with id and ip
    [Arguments]    ${node-id}    ${ovs-version}=23    ${router-id-ipv4}=10.0.0.1
    ${request}    Set Element Text    ${NODE_ISIS}    ${node-id}    xpath=.//node-id
    ${request}    Set Element Text    ${request}    ${ovs-version}    xpath=.//ovs-version
    ${request}    Set Element Text
    ...    ${request}
    ...    ${router-id-ipv4}
    ...    xpath=.//igp-node-attributes/isis-node-attributes/ted/te-router-id-ipv4
    ${request}    Element to String    ${request}
    RETURN    ${request}

Create Openflow Node
    [Documentation]    Create an Openflow node element with id and ip
    [Arguments]    ${node-id}    ${ip-address}=10.0.0.1    ${serial-number}=27
    ${request}    Set Element Text    ${NODE_OPENFLOW}    ${node-id}    xpath=.//id
    ${request}    Set Element Text    ${request}    ${ip-address}    xpath=.//ip-address
    ${request}    Set Element Text    ${request}    ${serial-number}    xpath=.//serial-number
    ${request}    Element to String    ${request}
    RETURN    ${request}

Create OVSDB Termination Point
    [Documentation]    Create an OVSDB termination point element with id and port
    [Arguments]    ${tp-id}    ${ofport}
    ${request}    Set Element Text    ${TERMINATION_POINT_OVSDB}    ${tp-id}    xpath=.//tp-id
    ${request}    Set Element Text    ${request}    ${ofport}    xpath=.//ofport
    ${request}    Element to String    ${request}
    RETURN    ${request}

Create Openflow Node Connector
    [Documentation]    Create an Openflow node connector element with id and port number
    [Arguments]    ${nc-id}    ${port-number}
    ${request}    Set Element Text    ${NODE_CONNECTOR_OPENFLOW}    ${nc-id}    xpath=.//id
    ${request}    Set Element Text    ${request}    ${port-number}    xpath=.//port-number
    ${request}    Element to String    ${request}
    RETURN    ${request}

Create Link
    [Arguments]    ${link-id}    ${source-node}    ${dest-node}    ${name}    ${metric}
    ${request}    Set Element Text    ${LINK}    ${link-id}    xpath=.//link-id
    ${request}    Set Element Text    ${request}    ${source-node}    xpath=.//source/source-node
    ${request}    Set Element Text    ${request}    ${dest-node}    xpath=.//destination/dest-node
    ${request}    Set Element Text    ${request}    ${name}    xpath=.//igp-link-attributes/name
    ${request}    Set Element Text    ${request}    ${metric}    xpath=.//igp-link-attributes/metric
    ${request}    Element to String    ${request}
    RETURN    ${request}

Extract Node from Topology
    [Documentation]    Returns node that contains supporting node with ID specified in argument supp_node_id
    [Arguments]    ${topology}    ${supp_node_id}
    ${xpath}    Set Variable    .//node/supporting-node[node-ref='${supp_node_id}']/..
    ${node}    Get Element    ${topology}    xpath=${xpath}
    ${node}    Element to String    ${node}
    RETURN    ${node}

Extract Termination Point from Topology
    [Documentation]    Returns termination point that contains supporting termination point from specified topology, node and with specified id
    [Arguments]    ${model}    ${topology}    ${topo_id}    ${node_id}    ${tp_id}
    Check Supported Model    ${model}
    ${xpath}    Set Variable If
    ...    '${model}' == 'network-topology-model' or '${model}' == 'opendaylight-inventory-model'
    ...    .//termination-point[tp-ref='/network-topology:network-topology/topology/${topo_id}/node/${node_id}/termination-point/${tp_id}']
    ...    .//termination-point/supporting-termination-point[tp-ref='${tp_id}']/..
    ${tp}    Get Element    ${topology}    xpath=${xpath}
    ${tp}    Element to String    ${tp}
    RETURN    ${tp}

Extract Link from Topology
    [Documentation]    Returns link that contains supporting link
    [Arguments]    ${model}    ${topology}    ${topo_id}    ${link_id}
    Check Supported Model    ${model}
    ${xpath}    Set Variable If
    ...    '${model}' == 'network-topology-model' or '${model}' == 'opendaylight-inventory-model'
    ...    .//link/supporting-link[link-ref='/network-topology/topology/${topo_id}/link/${link_id}']/..
    ...    .//link/supporting-link[tp-ref='${tp_id}']/..
    ${link}    Get Element    ${topology}    xpath=${xpath}
    ${link}    Element to String    ${link}
    RETURN    ${link}

Check Supported Model
    [Documentation]    Checks if model is supported.
    [Arguments]    ${model}
    IF    '${model}' != 'network-topology-model' and '${model}' != 'i2rs-model' and '${model}' != 'opendaylight-inventory-model'
        Fail    Not supported model
    END

Check Aggregated Node in Topology
    [Documentation]    Checks number of termination points and concrete supporting nodes in aggregated node and returns overlay node id. Model should be 'network-topology-model', 'opendaylight-inventory-model' or 'i2rs-model'.
    [Arguments]    ${model}    ${topology}    ${tp_count}    @{supp_node_ids}
    Check Supported Model    ${model}
    ${node_id}    Get From List    ${supp_node_ids}    0
    ${aggregated_node}    Extract Node from Topology    ${topology}    ${node_id}
    ${supp_node_count}    Get Length    ${supp_node_ids}
    Should Contain X Times    ${aggregated_node}    <supporting-node>    ${supp_node_count}
    Should Contain X Times    ${aggregated_node}    <termination-point>    ${tp_count}
    Should Contain X Times    ${aggregated_node}    <tp-ref>    ${tp_count}
    FOR    ${supp_node_id}    IN    @{supp_node_ids}
        Element Text Should Be
        ...    ${aggregated_node}
        ...    ${supp_node_id}
        ...    xpath=.//supporting-node[node-ref='${supp_node_id}']/node-ref
    END
    ${overlay_node_id}    Get Element Text    ${aggregated_node}    xpath=./node-id
    RETURN    ${overlay_node_id}

Check Aggregated Termination Point in Node
    [Documentation]    Checks supporting termination points in aggregated termination point. Model should be 'network-topology-model', 'opendaylight-inventory-model' or 'i2rs-model'.
    [Arguments]    ${model}    ${topology}    ${topology_id}    ${node_id}    ${tp_id}    @{supp_tp_ids}
    Check Supported Model    ${model}
    ${tp}    Extract Termination Point from Topology
    ...    ${model}
    ...    ${topology}
    ...    ${topology_id}
    ...    ${node_id}
    ...    ${tp_id}
    ${supp_tp_count}    Get Length    ${supp_tp_ids}
    Should Contain X Times    ${tp}    <tp-ref>    ${supp_tp_count}
    FOR    ${supp_tp_id}    IN    @{supp_tp_ids}
        Should Contain X Times    ${tp}    ${supp_tp_id}</tp-ref>    1
    END

Check Filtered Nodes in Topology
    [Documentation]    Checks nodes in filtered topology
    [Arguments]    ${topology}    ${tp_count}    @{node_ids}
    FOR    ${node_id}    IN    @{node_ids}
        Element Text Should Be
        ...    ${topology}
        ...    ${node_id}
        ...    xpath=.//node/supporting-node[node-ref='${node_id}']/node-ref
    END

Check Filtered Termination Points in Node
    [Documentation]    Checks termination points in filtered topology
    [Arguments]    ${topology}    ${supp_node_id}    @{supp_tp_ids}
    ${node}    Extract Node from Topology    ${topology}    ${supp_node_id}
    ${supp_tp_count}    Get Length    ${supp_tp_ids}
    Should Contain X Times    ${node}    <supporting-node>    1
    Should Contain X Times    ${node}    <termination-point>    ${supp_tp_count}
    Should Contain X Times    ${node}    <tp-ref>    ${supp_tp_count}
    FOR    ${supp_tp_id}    IN    @{supp_tp_ids}
        Should Contain X Times    ${node}    ${supp_tp_id}    1
    END

Check Filtered Links In Topology
    [Documentation]    Checks links in filtered topology
    [Arguments]    ${topology}    @{supp_link_ids}
    FOR    ${supp_link_id}    IN    @{supp_link_ids}
        Should Contain X Times    ${topology}    ${supp_link_id}</link-ref>    1
    END

Check Overlay Link Source And Destination
    [Documentation]    Checks if the overlay link's source and destination specified by a supporting link ref matches given source and destination
    [Arguments]    ${model}    ${topology}    ${topo_id}    ${link_id}    ${expected_source}    ${expected_destination}
    ${link}    Extract Link from Topology    ${model}    ${topology}    ${topo_id}    ${link_id}
    ${link_source}    Get Element Text    ${link}    xpath=.//source-node
    ${link_destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${link_source}    ${expected_source}
    Should Be Equal As Strings    ${link_destination}    ${expected_destination}

Output Topo Should Be Complete
    [Documentation]    Verifies that the output topology contains the expected amount of essential elements
    [Arguments]    ${node_count}=-1    ${supporting-node_count}=-1    ${node-ref_count}=-1    ${tp_count}=-1    ${tp-ref_count}=-1    ${link_count}=-1
    ...    ${link-ref_count}=-1
    ${resp}    Wait Until Keyword Succeeds    5x    250ms    Basic Request Get    ${OVERLAY_TOPO_URL}
    Should Contain    ${resp.text}    <topology-id>${OUTPUT_TOPO_NAME}</topology-id>
    IF    ${node_count}>-1
        Should Contain X Times    ${resp.text}    <node>    ${node_count}
    END
    IF    ${supporting-node_count}>-1
        Should Contain X Times    ${resp.text}    <supporting-node>    ${supporting-node_count}
    END
    IF    ${node-ref_count}>-1
        Should Contain X Times    ${resp.text}    <node-ref>    ${node-ref_count}
    END
    IF    ${link_count}>-1
        Should Contain X Times    ${resp.text}    <link>    ${link_count}
    END
    IF    ${link-ref_count}>-1
        Should Contain X Times    ${resp.text}    <link-ref>    ${link-ref_count}
    END
    IF    ${tp_count}>-1
        Should Contain X Times    ${resp.text}    <termination-point>    ${tp_count}
    END
    IF    ${tp-ref_count}>-1
        Should Contain X Times    ${resp.text}    <tp-ref>    ${tp-ref_count}
    END
    Log    ---- Output Topo ----
    Log    ${resp.text}
    RETURN    ${resp}

Set Global Variable If It Does Not Exist
    [Arguments]    ${name}    ${value}
    ${status}    ${message}    Run Keyword And Ignore Error    Variable Should Exist    ${name}
    IF    "${status}" == "FAIL"    Set Global Variable    ${name}    ${value}

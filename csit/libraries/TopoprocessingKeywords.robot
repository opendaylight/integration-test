*** Settings ***
Variables         ../variables/Variables.py
Variables         ../variables/topoprocessing/Topologies.py
Variables         ../variables/topoprocessing/TopologyRequests.py
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
Basic Request Put
    [Arguments]    ${request}    ${overlay_topology_url}
    [Documentation]    Send a simple HTTP PUT request to Configurational datastore
    ${resp}    Put Request    session    ${CONFIG_API}/${overlay_topology_url}    data=${request}
    Log    ${CONFIG_API}/${overlay_topology_url}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait For Karaf Log    Correlation configuration successfully read
    Wait For Karaf Log    Transaction successfully written

Basic Request Get And Test
    [Arguments]    ${overlay_topology_url}    ${should_contain}    ${times}
    [Documentation]    Send a simple HTTP GET request to a given URL and test if response contains the expected item X times
    ${resp}    Basic Request Get    ${overlay_topology_url}
    Should Contain X Times    ${resp.content}    ${should_contain}    ${times}
    [Return]    ${resp}

Basic Request Get
    [Arguments]    ${overlay_topology_url}
    [Documentation]    Send a simple HTTP GET request to a given URL
    ${resp}    Get Request    session    ${OPERATIONAL_API}/${overlay_topology_url}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp}

Send Basic Request And Test If Contain X Times
    [Arguments]    ${request}    ${overlay_topology_url}    ${should_contain}    ${times}
    [Documentation]    Send a basic HTTP PUT request to a given URL and test if response contains the expexted item X times
    Basic Request Put    ${request}    ${overlay_topology_url}
    ${resp}    Wait Until Keyword Succeeds    40x    250ms    Basic Request Get And Test    ${overlay_topology_url}    ${should_contain}
    ...    ${times}
    Log    ${resp.content}
    [Return]    ${resp}

Send Basic Delete Request
    [Documentation]    Sends a HTTP/DELETE request to a given URL
    [Arguments]    ${url}
    ${resp}    Delete Request    session    ${CONFIG_API}/${url}
    Log    Deleting ${CONFIG_API}/${url}
    [Return]    ${resp}

Delete Underlay Node
    [Documentation]    Deletes a node from an underlay topology
    [Arguments]    ${topology-id}    ${node-id}
    ${resp}    Send Basic Delete Request    network-topology:network-topology/topology/${topology-id}/node/${node-id}
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
    ${features}    Issue Command On Karaf Console    feature:list -i
    ${lines}    Get Lines Containing String    ${features}    odl-topoprocessing-framework
    ${length}    Get Length    ${lines}
    Install a Feature    odl-openflowplugin-nsf-model odl-topoprocessing-framework odl-topoprocessing-network-topology odl-topoprocessing-inventory odl-mdsal-models odl-ovsdb-southbound-impl    timeout=120
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

Test Teardown With Underlay Topologies Refresh
    [Arguments]    ${overlay_topology}
    [Documentation]    Deletes given overlay topology from datastore and overwrites the underlaying ones with initial topologies
    Test Teardown    ${overlay_topology}
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
    : FOR    ${index}    IN RANGE    1    7
    \    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/network-topo:${index}    data=${NETWORK_UNDERLAY_TOPOLOGY_${index}}
    \    Log    ${resp.content}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay nodes
    ${resp}    Put Request    session    ${CONFIG_API}/opendaylight-inventory:nodes    data=${OPENFLOW_UNDERLAY_NODES}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Openflow underlay topologies
    : FOR    ${index}    IN RANGE    1    7
    \    ${resp}    Put Request    session    ${CONFIG_API}/${TOPOLOGY_URL}/openflow-topo:${index}    data=${OPENFLOW_UNDERLAY_TOPOLOGY_${index}}
    \    Log    ${resp.content}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    Issue Command On Karaf Console    log:clear
    Log    ${resp.content}

Prepare Unification Inside Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo1}
    [Documentation]    Prepare topology request for unification inside from template
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text    ${request_template}    aggregation-only    xpath=.//correlations/correlation/type
    ${request_template}    Set Element Text    ${request_template}    ${correlation_item}    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text    ${request_template}    unification    xpath=.//correlation/aggregation/aggregation-type
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/aggregation/mapping[1]/input-model
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo1}    xpath=.//correlation/aggregation/mapping[1]/underlay-topology
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Prepare Unification Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo1}    ${underlay_topo2}
    [Documentation]    Prepare topology request for unification on two topologies from template
    ${request_template}    Prepare Unification Inside Topology Request    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo1}
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo2}    xpath=.//correlation/aggregation/mapping[2]/underlay-topology
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/aggregation/mapping[2]/input-model
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Prepare Unification Filtration Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${target_field1}    ${underlay_topo1}    ${target_field2}
    ...    ${underlay_topo2}
    [Documentation]    Prepare topology request for unification on two topologies from template
    ${request_template}    Prepare Unification Filtration Inside Topology Request    ${request_template}    ${model}    ${correlation_item}    ${target_field1}    ${underlay_topo1}
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo2}    xpath=.//correlation/aggregation/mapping[2]/underlay-topology
    Insert Target Field    ${request_template}    2    ${target_field2}    1
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
    Insert Target Field    ${request_template}    1    ${target-field}    1
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo}    xpath=.//correlation/filtration/underlay-topology
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Insert Apply Filters
    [Arguments]    ${request_template}    ${mapping}    ${filter_id}
    ${request_template}    Add Element    ${request_template}    ${APPLY_FILTERS}    xpath=.//correlation/aggregation/mapping[${mapping}]
    ${request_template}    Set Element Text    ${request_template}    ${filter_id}    xpath=.//correlation/aggregation/mapping[${mapping}]/apply-filters
    [Return]    ${request_template}

Prepare Filtration Topology Request
    [Arguments]    ${request_template}    ${model}    ${correlation_item}    ${underlay_topo}
    [Documentation]    Prepare topology request for filtration from template
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text    ${request_template}    ${correlation_item}    xpath=.//correlation/correlation-item
    ${request_template}    Set Element Text    ${request_template}    ${underlay_topo}    xpath=.//correlation/filtration/underlay-topology
    [Return]    ${request_template}

Insert Target Field
    [Arguments]    ${request_template}    ${mapping_index}    ${target_field_path}    ${matching_key}
    [Documentation]    Add target field to request
    ${target_field_template}    Set Element Text    ${TARGET_FIELD}    ${target_field_path}    xpath=.//target-field-path
    ${target_field_template}    Set Element Text    ${target_field_template}    ${matching_key}    xpath=.//matching-key
    ${request_template}    Add Element    ${request_template}    ${target_field_template}    xpath=.//correlation/aggregation/mapping[${mapping_index}]
    ${request_template}    Element to String    ${request_template}
    [Return]    ${request_template}

Insert Filter
    [Arguments]    ${request_template}    ${filter_template}    ${target_field}
    [Documentation]    Add filter to filtration
    ${request_template}    Add Element    ${request_template}    ${filter_template}    xpath=.//correlation/filtration
    ${model}    Get Element Text    ${request_template}    xpath=.//correlations/output-model
    ${request_template}    Set Element Text    ${request_template}    ${model}    xpath=.//correlation/filtration/filter/input-model
    ${request_template}    Set Element Text    ${request_template}    ${target_field}    xpath=.//correlation/filtration/filter/target-field
    [Return]    ${request_template}

Insert Filter With ID
    [Arguments]    ${request_template}    ${filter_template}    ${target_field}    ${filter_id}
    [Documentation]    Add filter to filtration with specified id
    ${request_template}    Insert Filter    ${request_template}    ${filter_template}    ${target_field}
    ${request_template}    Set Element Text    ${request_template}    ${filter_id}    xpath=.//correlation/filtration/filter/filter-id
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

Create Isis Node
    [Arguments]    ${node-id}    ${ovs-version}=23    ${router-id-ipv4}=10.0.0.1
    [Documentation]    Create an isis node element with id and ip
    ${request}    Set Element Text    ${NODE_ISIS}    ${node-id}    xpath=.//node-id
    ${request}    Set Element Text    ${request}    ${ovs-version}    xpath=.//ovs-version
    ${request}    Set Element Text    ${request}    ${router-id-ipv4}    xpath=.//igp-node-attributes/isis-node-attributes/ted/te-router-id-ipv4
    ${request}    Element to String    ${request}
    [Return]    ${request}

Create Openflow Node
    [Arguments]    ${node-id}    ${ip-address}=10.0.0.1    ${serial-number}=27
    [Documentation]    Create an Openflow node element with id and ip
    ${request}    Set Element Text    ${NODE_OPENFLOW}    ${node-id}    xpath=.//id
    ${request}    Set Element Text    ${request}    ${ip-address}    xpath=.//ip-address
    ${request}    Set Element Text    ${request}    ${serial-number}    xpath=.//serial-number
    ${request}    Element to String    ${request}
    [Return]    ${request}

Create OVSDB Termination Point
    [Arguments]    ${tp-id}    ${ofport}
    [Documentation]    Create an OVSDB termination point element with id and port
    ${request}    Set Element Text    ${TERMINATION_POINT_OVSDB}    ${tp-id}    xpath=.//tp-id
    ${request}    Set Element Text    ${request}    ${ofport}    xpath=.//ofport
    ${request}    Element to String    ${request}
    [Return]    ${request}

Create Openflow Node Connector
    [Arguments]    ${nc-id}    ${port-number}
    [Documentation]    Create an Openflow node connector element with id and port number
    ${request}    Set Element Text    ${NODE_CONNECTOR_OPENFLOW}    ${nc-id}    xpath=.//id
    ${request}    Set Element Text    ${request}    ${port-number}    xpath=.//port-number
    ${request}    Element to String    ${request}
    [Return]    ${request}

Create Link
    [Arguments]    ${link-id}    ${source-node}    ${dest-node}    ${name}    ${metric}
    ${request}    Set Element Text    ${LINK}    ${link-id}    xpath=.//link-id
    ${request}    Set Element Text    ${request}    ${source-node}    xpath=.//source/source-node
    ${request}    Set Element Text    ${request}    ${dest-node}    xpath=.//destination/dest-node
    ${request}    Set Element Text    ${request}    ${name}    xpath=.//igp-link-attributes/name
    ${request}    Set Element Text    ${request}    ${metric}    xpath=.//igp-link-attributes/metric
    ${request}    Element to String    ${request}
    [Return]    ${request}

Extract Node from Topology
    [Arguments]    ${topology}    ${supp_node_id}
    [Documentation]    Returns node that contains supporting node with ID specified in argument supp_node_id
    ${xpath}    Set Variable    .//node/supporting-node[node-ref='${supp_node_id}']/..
    ${node}    Get Element    ${topology}    xpath=${xpath}
    ${node}    Element to String    ${node}
    [Return]    ${node}

Extract Termination Point from Topology
    [Arguments]    ${model}    ${topology}    ${topo_id}    ${node_id}    ${tp_id}
    [Documentation]    Returns termination point that contains supporting termination point from specified topology, node and with specified id
    Check Supported Model    ${model}
    ${xpath}    Set Variable If    '${model}' == 'network-topology-model' or '${model}' == 'opendaylight-inventory-model'    .//termination-point[tp-ref='/network-topology:network-topology/topology/${topo_id}/node/${node_id}/termination-point/${tp_id}']    .//termination-point/supporting-termination-point[tp-ref='${tp_id}']/..
    ${tp}    Get Element    ${topology}    xpath=${xpath}
    ${tp}    Element to String    ${tp}
    [Return]    ${tp}

Extract Link from Topology
    [Arguments]    ${model}    ${topology}    ${topo_id}    ${link_id}
    [Documentation]    Returns link that contains supporting link
    Check Supported Model    ${model}
    ${xpath}    Set Variable If    '${model}' == 'network-topology-model' or '${model}' == 'opendaylight-inventory-model'    .//link/supporting-link[link-ref='/network-topology/topology/${topo_id}/link/${link_id}']/..    .//link/supporting-link[tp-ref='${tp_id}']/..
    ${link}    Get Element    ${topology}    xpath=${xpath}
    ${link}    Element to String    ${link}
    [Return]    ${link}

Check Supported Model
    [Arguments]    ${model}
    [Documentation]    Checks if model is supported.
    Run Keyword If    '${model}' != 'network-topology-model' and '${model}' != 'i2rs-model' and '${model}' != 'opendaylight-inventory-model'    Fail    Not supported model

Check Aggregated Node in Topology
    [Arguments]    ${model}    ${topology}    ${tp_count}    @{supp_node_ids}
    [Documentation]    Checks number of termination points and concrete supporting nodes in aggregated node and returns overlay node id. Model should be 'network-topology-model', 'opendaylight-inventory-model' or 'i2rs-model'.
    Check Supported Model    ${model}
    ${node_id}    Get From List    ${supp_node_ids}    0
    ${aggregated_node}    Extract Node from Topology    ${topology}    ${node_id}
    ${supp_node_count}    Get Length    ${supp_node_ids}
    Should Contain X Times    ${aggregated_node}    <supporting-node>    ${supp_node_count}
    Should Contain X Times    ${aggregated_node}    <termination-point>    ${tp_count}
    Should Contain X Times    ${aggregated_node}    <tp-ref>    ${tp_count}
    : FOR    ${supp_node_id}    IN    @{supp_node_ids}
    \    Element Text Should Be    ${aggregated_node}    ${supp_node_id}    xpath=.//supporting-node[node-ref='${supp_node_id}']/node-ref
    ${overlay_node_id}    Get Element Text    ${aggregated_node}    xpath=./node-id
    [Return]    ${overlay_node_id}

Check Aggregated Termination Point in Node
    [Arguments]    ${model}    ${topology}    ${topology_id}    ${node_id}    ${tp_id}    @{supp_tp_ids}
    [Documentation]    Checks supporting termination points in aggregated termination point. Model should be 'network-topology-model', 'opendaylight-inventory-model' or 'i2rs-model'.
    Check Supported Model    ${model}
    ${tp}    Extract Termination Point from Topology    ${model}    ${topology}    ${topology_id}    ${node_id}    ${tp_id}
    ${supp_tp_count}    Get Length    ${supp_tp_ids}
    Should Contain X Times    ${tp}    <tp-ref>    ${supp_tp_count}
    : FOR    ${supp_tp_id}    IN    @{supp_tp_ids}
    \    Should Contain X Times    ${tp}    ${supp_tp_id}</tp-ref>    1

Check Filtered Nodes in Topology
    [Arguments]    ${topology}    ${tp_count}    @{node_ids}
    [Documentation]    Checks nodes in filtered topology
    ${node_count}    Get Length    ${node_ids}
    Should Contain X Times    ${topology}    <node>    ${node_count}
    Should Contain X Times    ${topology}    <supporting-node>    ${node_count}
    Should Contain X Times    ${topology}    <termination-point>    ${tp_count}
    : FOR    ${node_id}    IN    @{node_ids}
    \    Element Text Should Be    ${topology}    ${node_id}    xpath=.//node/supporting-node[node-ref='${node_id}']/node-ref

Check Filtered Termination Points in Node
    [Arguments]    ${topology}    ${supp_node_id}    @{supp_tp_ids}
    [Documentation]    Checks termination points in filtered topology
    ${node}    Extract Node from Topology    ${topology}    ${supp_node_id}
    ${supp_tp_count}    Get Length    ${supp_tp_ids}
    Should Contain X Times    ${node}    <supporting-node>    1
    Should Contain X Times    ${node}    <termination-point>    ${supp_tp_count}
    Should Contain X Times    ${node}    <tp-ref>    ${supp_tp_count}
    : FOR    ${supp_tp_id}    IN    @{supp_tp_ids}
    \    Should Contain X Times    ${node}    ${supp_tp_id}    1

Check Filtered Links In Topology
    [Arguments]    ${topology}    @{supp_link_ids}
    [Documentation]    Checks links in filtered topology
    ${supp_link_count}    Get Length    ${supp_link_ids}
    Should Contain X Times    ${topology}    <link>    ${supp_link_count}
    Should Contain X Times    ${topology}    <link-ref>    ${supp_link_count}
    : FOR    ${supp_link_id}    IN    @{supp_link_ids}
    \    Should Contain X Times    ${topology}    ${supp_link_id}</link-ref>    1

Check Overlay Link Source And Destination
    [Arguments]    ${model}    ${topology}    ${topo_id}    ${link_id}    ${expected_source}    ${expected_destination}
    [Documentation]    Checks if the overlay link's source and destination specified by a supporting link ref matches given source and destination
    ${link}    Extract Link from Topology    ${model}    ${topology}    ${topo_id}    ${link_id}
    ${link_source}    Get Element Text    ${link}    xpath=.//source-node
    ${link_destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${link_source}    ${expected_source}
    Should Be Equal As Strings    ${link_destination}    ${expected_destination}

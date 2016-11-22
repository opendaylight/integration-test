*** Settings ***
Documentation     Test suite for Group Based Policy, sxp-ep-provider component.
Suite Setup       Suite startup
Suite Teardown    Delete All Sessions
Test Setup        Prepare_Ssh_Tooling
Test Teardown     Wipe clean ep templates and sxp node
Library           OperatingSystem    WITH NAME    os
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/GbpSxp.py    WITH NAME    gbpsxp
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/GbpSxp.robot

*** Variables ***
${EP_PROVIDER_TEMPLATES_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ep-provider-templates
${SXP_EP_PROVIDER_CONFIG_URI}    /restconf/config/sxp-ep-provider-model:sxp-ep-mapper
${SXP_NODE_CONFIG_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-node.json
${SXP_TOPOLOGY_NODE_CONFIG_URI}    /restconf/config/network-topology:network-topology/topology/sxp
${SXP_TOPOLOGY_NODE_OPERATIONAL_URI}    /restconf/operational/network-topology:network-topology/topology/sxp
${SXP_NODE_ADD_ENTRY_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-node-add-entry.json
${SXP_NODE_RPC_ADD_ENTRY_URI}    /restconf/operations/sxp-controller:add-entry
${GBP_RPC_UNREGISTER_ENDPOINT_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-rpc-unregister-endpoint.json
${GBP_RPC_UNREGISTER_ENDPOINT_URI}    /restconf/operations/base-endpoint:unregister-endpoint
${GBP_TENANT_CONFIG_URI}    /restconf/config/policy:tenants/tenant/tenant-red
${GBP_ENDPOINTS_URI}    /restconf/operational/base-endpoint:endpoints
${GBP_EXPECTED_ENDPOINTS_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-endpoint
${ISE_MOCK_SERVER_API_FOLDER}    mock-server-tc010
${ISE_REST_PORT}    9060
${ISE_API_DIR}    ${CURDIR}/../../../variables/gbp/ise-mock-server-api
${CONFIGURE_ISE_SOURCE_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ise-source.json

*** Test Cases ***
Register EP using manual inputs
    [Documentation]    Elicit endpoint registration by providing ep-policy-template, ep-forwarding-template and ip-sgt binding
    # ep-policy-templates + ep-forwarding-templates
    Add Elements To URI From File    ${SXP_EP_PROVIDER_CONFIG_URI}    ${EP_PROVIDER_TEMPLATES_FILE}-2.1.json
    # create sxp-node in topology
    Create sxp node    session    ${SXP_NODE_CONFIG_FILE}    1.1.1.1
    # ip-sgt binding in master DB
    Post Elements To URI From File    ${SXP_NODE_RPC_ADD_ENTRY_URI}    ${SXP_NODE_ADD_ENTRY_FILE}
    # wait for endpoint
    ${expected_endpoints}    os.Get file    ${GBP_EXPECTED_ENDPOINTS_FILE}-2.1.json
    Wait for endpoint and check    session    ${expected_endpoints}

Register EP using manual inputs and ise
    [Documentation]    Elicit endpoint registration by providing ep-forwarding-template and ip-sgt binding (ep-policy-template will loaded from ise-API)
    # ep-forwarding-templates
    Add Elements To URI From File    ${SXP_EP_PROVIDER_CONFIG_URI}    ${EP_PROVIDER_TEMPLATES_FILE}-2.2.json
    # setup ise mock-server
    Deploy_Ise_Mock_Server    ${ISE_MOCK_SERVER_API_FOLDER}    ${ISE_REST_PORT}
    ${ise_harvest_status_json}    Configure_Ise_Source_And_Gain_Harvest_Status    session    ${CONFIGURE_ISE_SOURCE_FILE}    http://${TOOLS_SYSTEM_IP}:${ISE_REST_PORT}
    Check_Ise_Harvest_Status    ${ise_harvest_status_json}    5
    Create sxp node    session    ${SXP_NODE_CONFIG_FILE}    1.1.1.1
    # ip-sgt binding in master DB
    Post Elements To URI From File    ${SXP_NODE_RPC_ADD_ENTRY_URI}    ${SXP_NODE_ADD_ENTRY_FILE}
    ${expected_endpoints}    os.Get file    ${GBP_EXPECTED_ENDPOINTS_FILE}-2.2.json
    Wait for endpoint and check    session    ${expected_endpoints}
    Clean_ise_source_config
    Teardown_Ise_Mock_Server    ${ISE_MOCK_SERVER_API_FOLDER}

*** Keywords ***
Suite startup
    [Documentation]    Setup session
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    KarafKeywords.Setup Karaf Keywords
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.sxp.core.threading

Wipe clean ep templates and sxp node
    [Documentation]    Delete sxp-ep-provider templates and sxp node
    # clean ep-templates
    Run keyword and ignore error    Remove All Elements If Exist    ${SXP_EP_PROVIDER_CONFIG_URI}
    # teardown sxp-node
    Run keyword and ignore error    Remove All Elements If Exist    ${SXP_TOPOLOGY_NODE_CONFIG_URI}
    # clean epg
    Run keyword and ignore error    Remove All Elements If Exist    ${GBP_TENANT_CONFIG_URI}
    # unregister endpoint
    Post Elements To URI From File    ${GBP_RPC_UNREGISTER_ENDPOINT_URI}    ${GBP_RPC_UNREGISTER_ENDPOINT_FILE}
    Wait Until Keyword Succeeds    5    1    Check for clean endpoints    session
    Teardown_Ssh_Tooling

Check for clean endpoints
    [Arguments]    ${session_arg}
    [Documentation]    Ensure that there are no endpoints in the system
    ${actual_endpoints}    Get Data From URI    ${session_arg}    ${GBP_ENDPOINTS_URI}
    ${actual_endpoints_json}    Json Parse From String    ${actual_endpoints}
    Should be empty    ${actual_endpoints_json['endpoints']['address-endpoints']}

Wait for endpoint and check
    [Arguments]    ${session_arg}    ${expected_endpoints}
    [Documentation]    Wait for endpoint to appear in DS/operational and compare to expected endpoint
    ${actual_endpoints_no_timestamp}    Wait Until Keyword Succeeds    5    1    Get endpoints and clean timestamp    ${session_arg}
    # check endpoint content
    Normalize_Jsons_And_Compare    ${expected_endpoints}    ${actual_endpoints_no_timestamp}

Get endpoints and clean timestamp
    [Arguments]    ${session_arg}
    [Documentation]    Read endpoints from DS/operational and clean timestamp for simple comparison
    ${actual_endpoints}    Get Data From URI    ${session_arg}    ${GBP_ENDPOINTS_URI}
    ${actual_endpoints_json}    Json Parse From String    ${actual_endpoints}
    ${actual_endpoints_no_timestamp}    gbpsxp.Remove endpoint timestamp    ${actual_endpoints_json}
    [Return]    ${actual_endpoints_no_timestamp}

Create sxp node
    [Arguments]    ${session_arg}    ${sxp_node_config_file}    ${sxp_node_id}
    [Documentation]    Create sxp node and wait till it appears in DS/operational
    # create sxp-node in topology
    Add Elements To URI From File And Verify    ${SXP_TOPOLOGY_NODE_CONFIG_URI}/node/${sxp_node_id}    ${sxp_node_config_file}
    ${sxp_node_config_readback}    Get Data From URI    ${session_arg}    ${SXP_TOPOLOGY_NODE_CONFIG_URI}/node/${sxp_node_id}
    # wait till it appears in DS/operational
    Wait until keyword succeeds    20    2    Check if sxp node is enabled    ${session_arg}    ${SXP_TOPOLOGY_NODE_OPERATIONAL_URI}/node/${sxp_node_id}

Check if sxp node is enabled
    [Arguments]    ${session_arg}    ${node_uri}
    [Documentation]    Read node enabled leaf and check if it is true
    ${sxp_node}    Get Data From URI    ${session_arg}    ${node_uri}
    ${sxp_node_json}    Json Parse From String    ${sxp_node}
    ${sxp_node_enabled}    gbpsxp.Resolve sxp node is enabled    ${sxp_node_json}
    should be equal as strings    True    ${sxp_node_enabled}

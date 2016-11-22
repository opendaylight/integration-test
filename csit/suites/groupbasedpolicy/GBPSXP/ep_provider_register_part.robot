*** Settings ***
Documentation     Test suite for Group Based Policy, sxp-ep-provider component.
Suite Setup       Suite_Startup
Suite Teardown    Suite_Cleanup
Test Setup        GbpSxp.Prepare_Ssh_Tooling
Test Teardown     Wipe_Clean_Ep_Templates_And_Sxp_Node
Library           OperatingSystem    WITH NAME    os
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/GbpSxp.py    WITH NAME    gbpsxp
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/GbpSxp.robot

*** Variables ***
${EP_PROVIDER_TEMPLATES_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ep-provider-templates
${SXP_NODE_CONFIG_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-node.json
${SXP_NODE_ADD_ENTRY_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-node-add-entry.json
${GBP_RPC_UNREGISTER_ENDPOINT_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-rpc-unregister-endpoint.json
${GBP_EXPECTED_ENDPOINTS_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-endpoint
${ISE_MOCK_SERVER_API_FOLDER}    mock-server-tc010
${CONFIGURE_ISE_SOURCE_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ise-source.json
${SXP_NODE_NAME}    1.1.1.1

*** Test Cases ***
Register_EP_Using_Manual_Inputs
    [Documentation]    Elicit endpoint registration by providing ep-policy-template, ep-forwarding-template and ip-sgt binding
    Utils.Add_Elements_To_URI_From_File    ${SXP_EP_PROVIDER_CONFIG_URI}    ${EP_PROVIDER_TEMPLATES_FILE}-2.1.json
    Create_sxp_node    session    ${SXP_NODE_CONFIG_FILE}    1.1.1.1
    Utils.Post_Elements_To_URI_From_File    ${SXP_NODE_RPC_ADD_ENTRY_URI}    ${SXP_NODE_ADD_ENTRY_FILE}
    ${expected_endpoints}    os.Get_File    ${GBP_EXPECTED_ENDPOINTS_FILE}-2.1.json
    Wait_For_Endpoint_And_Check    session    ${expected_endpoints}

Register_EP_Using_Manual_Inputs_And_Ise
    [Documentation]    Elicit endpoint registration by providing ep-forwarding-template and ip-sgt binding (ep-policy-template will loaded from ise-API)
    Utils.Add_Elements_To_URI_From_File    ${SXP_EP_PROVIDER_CONFIG_URI}    ${EP_PROVIDER_TEMPLATES_FILE}-2.2.json
    gbpsxp.Deploy_Ise_Mock_Server    ${ISE_MOCK_SERVER_API_FOLDER}    ${ISE_REST_PORT}
    ${ise_harvest_status_json}    gbpsxp.Configure_Ise_Source_And_Gain_Harvest_Status    session    ${CONFIGURE_ISE_SOURCE_FILE}    http://${TOOLS_SYSTEM_IP}:${ISE_REST_PORT}
    gbpsxp.Check_Ise_Harvest_Status    ${ise_harvest_status_json}    5
    Create_sxp_node    session    ${SXP_NODE_CONFIG_FILE}    ${SXP_NODE_NAME}
    Utils.Post_Elements_To_URI_From_File    ${SXP_NODE_RPC_ADD_ENTRY_URI}    ${SXP_NODE_ADD_ENTRY_FILE}
    ${expected_endpoints}    os.Get_File    ${GBP_EXPECTED_ENDPOINTS_FILE}-2.2.json
    Wait_For_Endpoint_And_Check    session    ${expected_endpoints}
    gbpsxp.Clean_ise_source_config
    gbpsxp.Teardown_Ise_Mock_Server    ${ISE_MOCK_SERVER_API_FOLDER}

*** Keywords ***
Suite_Startup
    [Documentation]    Setup session and set karaf log levels
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    KarafKeywords.Setup_Karaf_Keywords
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.sxp
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.groupbasedpolicy.renderer
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.groupbasedpolicy.sxp
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.groupbasedpolicy.sxp_ep_provider

Suite_Cleanup
    [Documentation]    Cleanup session and set karaf log levels to default
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set INFO org.opendaylight.sxp
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set INFO org.opendaylight.groupbasedpolicy.renderer
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set INFO org.opendaylight.groupbasedpolicy.sxp
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set INFO org.opendaylight.groupbasedpolicy.sxp_ep_provider
    RequestsLibrary.Delete_All_Sessions

Wipe_Clean_Ep_Templates_And_Sxp_Node
    [Documentation]    Delete sxp-ep-provider templates and sxp node
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SXP_EP_PROVIDER_CONFIG_URI}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SXP_TOPOLOGY_NODE_CONFIG_URI}/node/${SXP_NODE_NAME}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${GBP_TENANT_CONFIG_URI}
    Utils.Post_Elements_To_URI_From_File    ${GBP_RPC_UNREGISTER_ENDPOINT_URI}    ${GBP_RPC_UNREGISTER_ENDPOINT_FILE}
    BuiltIn.Wait_Until_Keyword_Succeeds    5    1    Check_For_Clean_Endpoints    session
    gbpsxp.Teardown_Ssh_Tooling

Check_For_Clean_Endpoints
    [Arguments]    ${session_arg}
    [Documentation]    Ensure that there are no endpoints in the system
    ${actual_endpoints}    Utils.Get_Data_From_URI    ${session_arg}    ${GBP_ENDPOINTS_URI}
    ${actual_endpoints_json}    Utils.Json_Parse_From_String    ${actual_endpoints}
    BuiltIn.Should_Be_Empty    ${actual_endpoints_json['endpoints']['address-endpoints']}

Wait_For_Endpoint_And_Check
    [Arguments]    ${session_arg}    ${expected_endpoints}
    [Documentation]    Wait for endpoint to appear in DS/operational and compare to expected endpoint
    ${actual_endpoints_no_timestamp}    BuiltIn.Wait_Until_Keyword_Succeeds    5    1    Get_Endpoints_And_Clean_Timestamp    ${session_arg}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_endpoints}    ${actual_endpoints_no_timestamp}

Get_Endpoints_And_Clean_Timestamp
    [Arguments]    ${session_arg}
    [Documentation]    Read endpoints from DS/operational and clean timestamp for simple comparison
    ${actual_endpoints}    Utils.Get_Data_From_URI    ${session_arg}    ${GBP_ENDPOINTS_URI}
    ${actual_endpoints_json}    Utils.Json_Parse_From_String    ${actual_endpoints}
    ${actual_endpoints_no_timestamp}    gbpsxp.Remove_Endpoint_Timestamp    ${actual_endpoints_json}
    [Return]    ${actual_endpoints_no_timestamp}

Create_sxp_node
    [Arguments]    ${session_arg}    ${sxp_node_config_file}    ${sxp_node_id}
    [Documentation]    Create sxp node and wait till it appears in DS/operational
    ${previous_topology_config}    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Get_Data_From_URI    ${session_arg}    ${SXP_TOPOLOGY_NODE_CONFIG_URI}
    BuiltIn.Log    ${previous_topology_config}
    Utils.Add_Elements_To_URI_From_File_And_Verify    ${SXP_TOPOLOGY_NODE_CONFIG_URI}/node/${sxp_node_id}    ${sxp_node_config_file}
    ${sxp_node_config_readback}    Utils.Get_Data_From_URI    ${session_arg}    ${SXP_TOPOLOGY_NODE_CONFIG_URI}/node/${sxp_node_id}
    BuiltIn.Wait_Until_Keyword_Succeeds    20    2    Check_If_Sxp_Node_Is_Enabled    ${session_arg}    ${SXP_TOPOLOGY_NODE_OPERATIONAL_URI}/node/${sxp_node_id}

Check_If_Sxp_Node_Is_Enabled
    [Arguments]    ${session_arg}    ${node_uri}
    [Documentation]    Read node enabled leaf and check if it is true
    ${sxp_node}    Utils.Get_Data_From_URI    ${session_arg}    ${node_uri}
    ${sxp_node_json}    Utils.Json_Parse_From_String    ${sxp_node}
    ${sxp_node_enabled}    gbpsxp.Resolve_sxp_node_is_enabled    ${sxp_node_json}
    BuiltIn.Should_Be_Equal_As_Strings    True    ${sxp_node_enabled}

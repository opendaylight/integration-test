*** Settings ***
Documentation     Test suite for Group Based Policy, sxp-ep-provider component.
Suite Setup       Setup_Http_And_Netconf
Suite Teardown    Teardown_Http_And_Netconf
Test Setup        Prepare_Renderer_Prerequisities
Test Teardown     Wipe_Clean_Renderer_Policy_Cohort
Library           OperatingSystem    WITH NAME    os
Library           RequestsLibrary    WITH NAME    reqLib
Library           SSHLibrary
Library           ../../../libraries/GbpSxp.py    WITH NAME    gbpsxp
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/NetconfKeywords.robot
Resource          ../../../libraries/GbpSxp.robot

*** Variables ***
${EP_PROVIDER_TEMPLATES_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ep-policy-templates
${IOS_XE_SCHEMAS_FOLDER}    ${CURDIR}/../../../variables/gbp/ios-xe-schemas
${GBP_RENDERER_POLICY_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-renderer-policy.json
# netconf
@{IOS_XE_IP}      ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
@{IOS_XE_NODE_NAMES}    ios-xe-mock-1    ios-xe-mock-2
${NETCONF_CONFIG_IOSXE_NODE_FILE}    ${CURDIR}/../../../variables/gbp/ios-xe-netconf-node.json
# sfc configuration
${SFC_SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-functions.json
${SFC_SF_FORWARDERS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-function-forwarders.json
${SFC_SF_CHAINS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-function-chains.json
${SFC_SF_PATHS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-function-paths.json

*** Test Cases ***
Configure_Sfc_And_Ios_Xe_Renderer_Using_Generated_Sgt
    [Documentation]    Elicit netconf device configuration by providing sfc configurations and ios-xe renderer policy
    ${renderer_policy}    ${next_version}    Provision_renderer_policy    session    ${GBP_RENDERER_POLICY_FILE}
    Utils.Add_Elements_To_URI_And_Verify    ${GBP_RENDERER_CONFIG_URI}/renderer-policy    ${renderer_policy}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    2    Check_Renderer_Policy_Status_Version    session    ${next_version}
    ${security_group_json}    BuiltIn.Wait_Until_Keyword_Succeeds    20    2    Seek_Security_Group    session    ${NETCONF_CONFIG_URI}/node/${IOS_XE_NODE_NAMES[1]}/${MOUNTPOINT_IOSXE_SUFFIX}
    BuiltIn.Log    ${security_group_json['source']['tag']}    level=DEBUG
    BuiltIn.Log    ${security_group_json['destination']['tag']}    level=DEBUG
    BuiltIn.Should_Be_Equal_As_Integers    100    ${security_group_json['source']['tag']}
    BuiltIn.Should_Be_Equal_As_Integers    101    ${security_group_json['destination']['tag']}
    ${expected_templates}    os.Get_File    ${EP_PROVIDER_TEMPLATES_FILE}-3.1.json
    ${actual_templates}    Utils.Get_Data_From_URI    session    ${SXP_EP_PROVIDER_CONFIG_URI}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_templates}    ${actual_templates}

Configure_Sfc_And_Ios_Xe_Renderer_Using_Existing_Sgt
    [Documentation]    Elicit netconf device configuration by providing sfc configurations and ios-xe renderer policy and ep-policy-templates
    Utils.Add_Elements_To_URI_From_File    ${SXP_EP_PROVIDER_CONFIG_URI}    ${EP_PROVIDER_TEMPLATES_FILE}-3.2.json
    ${renderer_policy}    ${next_version}    Provision_renderer_policy    session    ${GBP_RENDERER_POLICY_FILE}
    Utils.Add_Elements_To_URI_And_Verify    ${GBP_RENDERER_CONFIG_URI}/renderer-policy    ${renderer_policy}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    2    Check_Renderer_Policy_Status_Version    session    ${next_version}
    ${security_group_json}    BuiltIn.Wait_Until_Keyword_Succeeds    20    2    Seek_Security_Group    session    ${NETCONF_CONFIG_URI}/node/${IOS_XE_NODE_NAMES[1]}/${MOUNTPOINT_IOSXE_SUFFIX}
    BuiltIn.Log    ${security_group_json['source']['tag']}    level=DEBUG
    BuiltIn.Log    ${security_group_json['destination']['tag']}    level=DEBUG
    BuiltIn.Should_Be_Equal_As_Integers    43    ${security_group_json['source']['tag']}
    BuiltIn.Should_Be_Equal_As_Integers    42    ${security_group_json['destination']['tag']}

*** Keywords ***
Setup_Http_And_Netconf
    [Documentation]    Setup http session, setup ssh session to tools, deploy netconf-testtool (with ios-xe schemas) and start
    reqLib.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${tools_1_session}    GbpSxp.Prepare_Ssh_Tooling    ${TOOLS_SYSTEM_IP}
    ${tools_2_session}    GbpSxp.Prepare_Ssh_Tooling    ${TOOLS_SYSTEM_2_IP}
    @{tools_sessions}    BuiltIn.Create_List    ${tools_1_session}    ${tools_2_session}
    BuiltIn.Set_Suite_Variable    ${TOOLS_SESSIONS}    ${tools_sessions}
    NetconfKeywords.Setup_NetconfKeywords
    ${run_netconf_testtool_manually}    BuiltIn.Get_Variable_Value    ${run_netconf_testtool_manually}    ${False}
    ${logfile}    Utils.Get_Log_File_Name    testtool
    BuiltIn.Run_Keyword_If    ${run_netconf_testtool_manually}    BuiltIn.Set_Suite_Variable    ${testtool_log}    ${logfile}
    FOR    ${ssh_session}    IN    @{TOOLS_SESSIONS}
        SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${ssh_session}
        BuiltIn.Run_Keyword_Unless    ${run_netconf_testtool_manually}    Install_And_Start_Testtool    device-count=1    debug=false    schemas=${IOS_XE_SCHEMAS_FOLDER}
        ...    mdsal=true
    END

Teardown_Http_And_Netconf
    [Documentation]    Close http session, close ssh session to tools, stop netconf-testtool
    FOR    ${ssh_session}    IN    @{TOOLS_SESSIONS}
        BuiltIn.Log    ${ssh_session}
        SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${ssh_session}
        Stop_Testtool
    END
    gbpsxp.Teardown_Ssh_Tooling    ${TOOLS_SESSIONS}
    RequestsLibrary.Delete_All_Sessions

Prepare_Renderer_Prerequisities
    [Documentation]    Prepare sfc configurations, connect netconf device
    FOR    ${INDEX}    IN RANGE    0    2
        BuiltIn.Log    ${INDEX}
        ${netconf_node_configuration_json}    Utils.Json_Parse_From_File    ${NETCONF_CONFIG_IOSXE_NODE_FILE}
        ${netconf_node_configuration}    gbpsxp.Replace_Netconf_Node_Host    ${netconf_node_configuration_json}    ${IOS_XE_NODE_NAMES[${INDEX}]}    ${IOS_XE_IP[${INDEX}]}
        BuiltIn.Log    ${netconf_node_configuration}    level=DEBUG
        Utils.Add_Elements_To_URI_And_Verify    ${NETCONF_CONFIG_URI}/node/${IOS_XE_NODE_NAMES[${INDEX}]}    ${netconf_node_configuration}
    END
    FOR    ${INDEX}    IN RANGE    0    2
        BuiltIn.Log    ${INDEX}
        BuiltIn.Wait_Until_Keyword_Succeeds    30    2    Check_Netconf_Node_Status    session    ${NETCONF_OPERATIONAL_URI}/node/${IOS_XE_NODE_NAMES[${INDEX}]}
        BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_From_Uri    ${NETCONF_CONFIG_URI}/node/${IOS_XE_NODE_NAMES[${INDEX}]}/yang-ext:mount    session=session
    END
    Utils.Add_Elements_To_URI_From_File    ${SERVICE_FUNCTIONS_URI}    ${SFC_SERVICE_FUNCTIONS_FILE}
    &{ip_mgmt_map}    BuiltIn.Create_Dictionary    SFF1=${TOOLS_SYSTEM_2_IP}    SFF2=${TOOLS_SYSTEM_IP}
    ${sfc_sf_forwarders_json}    Utils.Json_Parse_From_File    ${SFC_SF_FORWARDERS_FILE}
    ${sfc_sf_forwarders}    gbpsxp.Replace_Ip_Mgmt_Address_In_Forwarder    ${sfc_sf_forwarders_json}    ${ip_mgmt_map}
    Utils.Add_Elements_To_URI_And_Verify    ${SERVICE_FORWARDERS_URI}    ${sfc_sf_forwarders}
    Utils.Add_Elements_To_URI_From_File    ${SERVICE_CHAINS_URI}    ${SFC_SF_CHAINS_FILE}
    Utils.Add_Elements_To_URI_From_File    ${SERVICE_FUNCTION_PATHS_URI}    ${SFC_SF_PATHS_FILE}

Check_Netconf_Node_Status
    [Arguments]    ${session_arg}    ${node_operational_uri}
    [Documentation]    Check if connection status of given node is 'connected'
    ${node_content}    Utils.Get_Data_From_URI    ${session_arg}    ${node_operational_uri}
    ${node_content_json}    Utils.Json_Parse_From_String    ${node_content}
    BuiltIn.Should_Be_Equal_As_Strings    connected    ${node_content_json['node'][0]['netconf-node-topology:connection-status']}

Wipe_Clean_Renderer_Policy_Cohort
    [Documentation]    Delete ep-policy-templates, renderer-policy, sfc configuraions, netconf-device config
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SERVICE_FUNCTIONS_URI}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SERVICE_FORWARDERS_URI}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SERVICE_CHAINS_URI}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SERVICE_FUNCTION_PATHS_URI}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${GBP_RENDERER_CONFIG_URI}
    # clean netconf-device config (behind mountpoint) and disconnect by removing it from DS/config
    FOR    ${ios_xe_node_name}    IN    @{IOS_XE_NODE_NAMES}
        BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${NETCONF_CONFIG_URI}/node/${ios_xe_node_name}/${MOUNTPOINT_IOSXE_SUFFIX}
        BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${NETCONF_CONFIG_URI}/node/${ios_xe_node_name}
    END
    FOR    ${ios_xe_node_name}    IN    @{IOS_XE_NODE_NAMES}
        BuiltIn.Wait_Until_Keyword_Succeeds    5    1    Utils.No_Content_From_URI    session    ${NETCONF_OPERATIONAL_URI}/node/${ios_xe_node_name}
    END
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SXP_EP_PROVIDER_CONFIG_URI}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${GBP_TENANT_CONFIG_URI}

Seek_Security_Group
    [Arguments]    ${session_arg}    ${config_uri}
    [Documentation]    Read given DS and seek CONFIG['native']['class-map'][0]['match']['security-group']
    ${device_ds_config}    Utils.Get_Data_From_URI    ${session_arg}    ${config_uri}
    ${device_ds_config_json}    Utils.Json_Parse_From_String    ${device_ds_config}
    [Return]    ${device_ds_config_json['native']['class-map'][0]['match']['security-group']}

Propose_Renderer_Configuration_Next_Version
    [Arguments]    ${session_arg}
    [Documentation]    Read current renderer configuration status and compute next version or use 0 if status absents
    ${renderer_policy}    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Get_Data_From_URI    ${session_arg}    ${GBP_RENDERER_POLICY_OPERATIONAL_URI}
    BuiltIn.Return_From_Keyword_If    '${renderer_policy[0]}' != 'PASS'    0
    ${renderer_policy_json}    Utils.Json_Parse_From_String    ${renderer_policy[1]}
    ${current_version}    BuiltIn.Convert_To_Integer    ${renderer_policy_json['renderer-policy']['version']}
    [Return]    ${current_version + 1}

Provision_renderer_policy
    [Arguments]    ${session_arg}    ${renderer_policy_file}
    [Documentation]    Replace version number in given renderer-policy in order to be the next expected value
    ${renderer_policy_json}    Utils.Json_Parse_From_File    ${renderer_policy_file}
    ${next_version}    Propose_Renderer_Configuration_Next_Version    ${session_arg}
    ${renderer_policy_updated}    gbpsxp.Replace_Renderer_Policy_Version    ${renderer_policy_json}    ${next_version}
    [Return]    ${renderer_policy_updated}    ${next_version}

Check_Renderer_Policy_Status_Version
    [Arguments]    ${session_arg}    ${expected_version}
    [Documentation]    Read current renderer policy version and compare it to expected version
    ${renderer_policy}    Utils.Get_Data_From_URI    ${session_arg}    ${GBP_RENDERER_POLICY_OPERATIONAL_URI}
    ${renderer_policy_json}    Utils.Json_Parse_From_String    ${renderer_policy}
    BuiltIn.Should_Be_Equal_As_Integers    ${renderer_policy_json['renderer-policy']['version']}    ${expected_version}

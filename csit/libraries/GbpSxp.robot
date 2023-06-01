*** Settings ***
Documentation       GbpSxp library covering common tasks of gbp-sxp test cases.

Library             OperatingSystem    WITH NAME    os
Library             SSHLibrary
Library             RequestsLibrary
Library             DateTime
Library             ./GbpSxp.py    WITH NAME    gbpsxp
Resource            ../variables/Variables.robot
Resource            ./Utils.robot
Resource            ./SSHKeywords.robot


*** Variables ***
${ISE_API_DIR}                                      ${CURDIR}/../variables/gbp/ise-mock-server-api
${ISE_REST_PORT}                                    9060
${GBP_ENDPOINTS_URI}                                /rests/data/base-endpoint:endpoints?content=nonconfig
${GBP_EP_TEMPLATES_CONFIG_URI}                      /rests/data/sxp-ep-provider-model:sxp-ep-mapper?content=config
${GBP_RENDERER_CONFIG_URI}                          /rests/data/renderer:renderers/renderer/ios-xe-renderer?content=config
${GBP_RENDERER_POLICY_OPERATIONAL_URI}
...                                                 /rests/data/renderer:renderers/renderer/ios-xe-renderer/renderer-policy?content=nonconfig
${GBP_RENDERER_POLICY_STATUS_OPERATIONAL_URI}       ${GBP_RENDERER_POLICY_OPERATIONAL_URI}/status
${GBP_RPC_UNREGISTER_ENDPOINT_URI}                  /rests/operations/base-endpoint:unregister-endpoint
${GBP_TENANT_CONFIG_URI}                            /rests/data/policy:tenants/tenant/tenant-red?content=config
${MOUNTPOINT_IOSXE_SUFFIX}                          yang-ext:mount/ned:native
${NETCONF_CONFIG_URI}
...                                                 /rests/data/network-topology:network-topology/topology/topology-netconf?content=config
${NETCONF_OPERATIONAL_URI}
...                                                 /rests/data/network-topology:network-topology/topology/topology-netconf?content=nonconfig
${SXP_EP_PROVIDER_CONFIG_URI}                       /rests/data/sxp-ep-provider-model:sxp-ep-mapper?content=config
${SXP_ISE_ADAPTER_CONFIG_URI}                       /rests/data/sxp-ise-adapter-model:gbp-sxp-ise-adapter?content=config
${SXP_ISE_ADAPTER_OPERATIONAL_URI}                  /rests/data/sxp-ise-adapter-model:gbp-sxp-ise-adapter?content=nonconfig
${SXP_NODE_RPC_ADD_ENTRY_URI}                       /rests/operations/sxp-controller:add-entry
${SXP_TOPOLOGY_NODE_CONFIG_URI}                     /rests/data/network-topology:network-topology/topology/sxp?content=config
${SXP_TOPOLOGY_NODE_OPERATIONAL_URI}
...                                                 /rests/data/network-topology:network-topology/topology/sxp?content=nonconfig


*** Keywords ***
Prepare_Ssh_Tooling
    [Documentation]    Setup ssh session to tools system
    [Arguments]    ${ip_address}=${TOOLS_SYSTEM_IP}
    ${tools_connection}    SSHKeywords.Open_Connection_To_Tools_System    ${ip_address}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    mock-server tornado==4.2
    ${sed_output}    SSHKeywords.Execute_Command_At_Path_Should_Pass
    ...    sed -r -i 's/^(DEFAULT_FORMAT = ).+$/\\1XML/' lib/python2.7/site-packages/mock_server/data.py
    ...    path=${SSHKeywords__current_venv_path}
    SSHKeywords.Virtual_Env_Freeze
    RETURN    ${tools_connection}

Deploy_Ise_Mock_Server
    [Documentation]    Deploy and start ise mock-server
    [Arguments]    ${ise_mock_server_api_folder}    ${ise_rest_port}
    # deploy ise mock-server
    SSHLibrary.Put_Directory    ${ISE_API_DIR}/${ise_mock_server_api_folder}    destination=.    recursive=True
    # start ise mock-server
    SSHKeywords.Virtual_Env_Activate_On_Current_Session
    SSHLibrary.Write
    ...    mock-server --dir=${ise_mock_server_api_folder} --port=${ise_rest_port} --address=${TOOLS_SYSTEM_IP} --debug
    BuiltIn.Wait_Until_Keyword_Succeeds    5    1    gbpsxp.Check_Ise_Mock_Server_Is_Online    ${ise_rest_port}
    ${mock_server_pid}    SSHKeywords.Execute_Command_Should_Pass    pgrep -f mock-server
    SSHKeywords.Execute_Command_Should_Pass    lsof -p ${mock_server_pid}

Teardown_Ise_Mock_Server
    [Documentation]    Stop and wipe clean ise mock-server
    [Arguments]    ${ise_mock_server_api_folder}
    # stop ise mock-server
    SSHLibrary.Execute_command    pkill -f mock-server    return_stderr=True    return_rc=False
    SSHKeywords.Execute_Command_Should_Pass
    ...    ls -la ${ise_mock_server_api_folder}; cat ${ise_mock_server_api_folder}/access-*.log
    # wipe ise mock-server deployment
    SSHLibrary.Execute_command    rm -rf ${ise_mock_server_api_folder}    return_stderr=True    return_rc=False

Teardown_Ssh_Tooling
    [Documentation]    Deactivate virtualenv and close ssh session on tools system
    [Arguments]    ${session_list}=@{EMPTY}
    FOR    ${ssh_session}    IN    @{session_list}
        BuiltIn.Log    ${ssh_session}
        SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${ssh_session}
        SSHKeywords.Virtual_Env_Deactivate_On_Current_Session
        SSHKeywords.Virtual_Env_Delete
        # fallback to single session
    END
    ${session_list_size}    get length    ${session_list}
    BuiltIn.Log    ${session_list_size}
    IF    ${session_list_size} == 0
        SSHKeywords.Virtual_Env_Deactivate_On_Current_Session
    END
    IF    ${session_list_size} == 0    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections

Configure_Ise_Source_And_Gain_Harvest_Status
    [Documentation]    Post ise-source configuration and wait for ise harvest status
    [Arguments]    ${session_arg}    ${configure_ise_source_file}    ${ise_rest_uri}
    # post ise-source configuration and wait for status
    ${sxp_source_config_json}    Utils.Json_Parse_From_File    ${configure_ise_source_file}
    gbpsxp.Replace_Ise_Source_Address    ${sxp_source_config_json}    ${ise_rest_uri}
    BuiltIn.Log    ${sxp_source_config_json}
    ${now}    DateTime.Get_Current_Date    result_format=%Y-%m-%dT%H:%M:%S.%f
    Utils.Post_Elements_To_URI    ${SXP_ISE_ADAPTER_CONFIG_URI}    ${sxp_source_config_json}
    ${ise_harvest_status_json}    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    20
    ...    1
    ...    Gain_Uptodate_Harvest_Status
    ...    ${session_arg}
    ...    ${now}
    RETURN    ${ise_harvest_status_json}

Gain_Uptodate_Harvest_Status
    [Documentation]    Read ise source harvest status and check if timestamp not older then limit
    [Arguments]    ${session_arg}    ${now_timestamp}
    ${ise_harvest_status}    Utils.Get_Data_From_URI    ${session_arg}    ${SXP_ISE_ADAPTER_OPERATIONAL_URI}
    ${ise_harvest_status_json}    Utils.Json_Parse_From_String    ${ise_harvest_status}
    ${status_timestamp}    BuiltIn.Set_Variable
    ...    ${ise_harvest_status_json['gbp-sxp-ise-adapter']['ise-harvest-status']['timestamp']}
    gbpsxp.Check_iso8601_datetime_younger_then_limit    ${status_timestamp}    ${now_timestamp}
    RETURN    ${ise_harvest_status_json}

Check_Ise_Mock_Server_Is_Online
    [Documentation]    Checks if the port ${ise_port} is occupied on tools system
    [Arguments]    ${ise_port}
    ${ise_port_occupied}    SSHLibrary.Execute_command
    ...    netstat -lnp | grep '${ise_port}'
    ...    return_stdout=False
    ...    return_rc=True
    BuiltIn.Should_Be_Equal_As_Integers    0    ${ise_port_occupied}

Check_Ise_Harvest_Status
    [Documentation]    Check ise harvest status by templatest written amount
    [Arguments]    ${ise_harvest_status_json}    ${expected_templates_amount}
    ${templates_written}    BuiltIn.Set_Variable
    ...    ${ise_harvest_status_json['gbp-sxp-ise-adapter']['ise-harvest-status']['templates-written']}
    BuiltIn.Should_Be_Equal_As_Integers    ${expected_templates_amount}    ${templates_written}

Clean_ise_source_config
    [Documentation]    Wipe clean ise source configuration
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${SXP_ISE_ADAPTER_CONFIG_URI}

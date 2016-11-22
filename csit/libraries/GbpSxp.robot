*** Settings ***
Documentation     GbpSxp library covering common tasks of gbp-sxp test cases.
Library           OperatingSystem    WITH NAME    os
Library           SSHLibrary
Library           RequestsLibrary
Library           DateTime
Library           ./GbpSxp.py    WITH NAME    gbpsxp
Variables         ../variables/Variables.py
Resource          ./Utils.robot
Resource          ./SSHKeywords.robot

*** Variables ***
${SXP_ISE_ADAPTER_CONFIG_URI}    /restconf/config/sxp-ise-adapter-model:gbp-sxp-ise-adapter
${SXP_ISE_ADAPTER_OPERATIONAL_URI}    /restconf/operational/sxp-ise-adapter-model:gbp-sxp-ise-adapter

*** Keywords ***
Prepare_Ssh_Tooling
    [Arguments]    ${ip_address}=${TOOLS_SYSTEM_IP}
    [Documentation]    Setup ssh session to tools system
    ${tools_connection}    SSHKeywords.Open_Connection_To_Tools_System    ${ip_address}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    mock-server tornado==4.2
    ${sed_output}    SSHKeywords.Execute_Command_At_Path_Should_Pass    sed -r -i 's/^(DEFAULT_FORMAT = ).+$/\\1XML/' lib/python2.7/site-packages/mock_server/data.py    path=${SSHKeywords__current_venv_path}
    SSHKeywords.Virtual_Env_Freeze
    [Return]    ${tools_connection}

Deploy_Ise_Mock_Server
    [Arguments]    ${ise_mock_server_api_folder}    ${ise_rest_port}
    [Documentation]    Deploy and start ise mock-server
    # deploy ise mock-server
    SSHLibrary.Put Directory    ${ISE_API_DIR}/${ise_mock_server_api_folder}    destination=.    recursive=True
    # start ise mock-server
    SSHKeywords.Virtual_Env_Activate_On_Current_Session
    SSHLibrary.Write    mock-server --dir=${ise_mock_server_api_folder} --port=${ise_rest_port} --debug
    Wait Until Keyword Succeeds    5    1    Check_Ise_Mock_Server_Is_Online    ${ise_rest_port}
    ${mock_server_pid}      SSHKeywords.Execute_Command_Should_Pass     pgrep -f mock-server
    SSHKeywords.Execute_Command_Should_Pass     lsof -p ${mock_server_pid}

Teardown_Ise_Mock_Server
    [Arguments]    ${ise_mock_server_api_folder}
    [Documentation]    Stop and wipe clean ise mock-server
    # stop ise mock-server
    SSHLibrary.Execute_command    pkill -f mock-server    return_stderr=True    return_rc=False
    SSHKeywords.Execute_Command_Should_Pass    ls -la ${ise_mock_server_api_folder}; cat ${ise_mock_server_api_folder}/access-*.log
    # wipe ise mock-server deployment
    SSHLibrary.Execute_command    rm -rf ${ise_mock_server_api_folder}    return_stderr=True    return_rc=False

Teardown_Ssh_Tooling
    [Arguments]    ${session_list}=@{EMPTY}
    [Documentation]    Deactivate virtualenv and close ssh session on tools system
    : FOR    ${ssh_session}    IN    @{session_list}
    \    Log    ${ssh_session}
    \    RESTORE_CURRENT_SSH_CONNECTION_FROM_INDEX    ${ssh_session}
    \    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session
    \    SSHKeywords.Virtual_Env_Delete
    # fallback to single session
    ${session_list_size}    get length    ${session_list}
    Log    ${session_list_size}
    Run keyword if    ${session_list_size} == 0    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session
    Run keyword if    ${session_list_size} == 0    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close All Connections

Configure_Ise_Source_And_Gain_Harvest_Status
    [Arguments]    ${session_arg}    ${configure_ise_source_file}    ${ise_rest_uri}
    [Documentation]    Post ise-source configuration and wait for ise harvest status
    # post ise-source configuration and wait for status
    ${sxp_source_config_json}    Json Parse From File    ${configure_ise_source_file}
    gbpsxp.Replace ise source address    ${sxp_source_config_json}    ${ise_rest_uri}
    log    ${sxp_source_config_json}
    ${now}    DateTime.Get Current Date    result_format=${ISO8601_DATETIME_FORMAT}
    Post Elements To URI    ${SXP_ISE_ADAPTER_CONFIG_URI}    ${sxp_source_config_json}
    ${ise_harvest_status_json}    Wait Until Keyword Succeeds    20    1    Gain_Uptodate_Harvest_Status    ${session_arg}    ${now}
    [Return]    ${ise_harvest_status_json}

Gain_Uptodate_Harvest_Status
    [Arguments]    ${session_arg}    ${now_timestamp}
    [Documentation]    Read ise source harvest status and check if timestamp not older then limit
    ${ise_harvest_status}    Get Data From URI    ${session_arg}    ${SXP_ISE_ADAPTER_OPERATIONAL_URI}
    ${ise_harvest_status_json}    Json Parse From String    ${ise_harvest_status}
    ${status_timestamp}    BuiltIn.Set_Variable    ${ise_harvest_status_json['gbp-sxp-ise-adapter']['ise-harvest-status']['timestamp']}
    gbpsxp.Check iso8601 datetime younger then limit    ${status_timestamp}    ${now_timestamp}
    [Return]    ${ise_harvest_status_json}

Check_Ise_Mock_Server_Is_Online
    [Arguments]    ${ise_port}
    [Documentation]    Checks if the port ${ise_port} is occupied on tools system
    ${ise_port_occupied}    SSHLibrary.Execute_command    netstat -lnp | grep '${ise_port}'    return_stdout=False    return_rc=True
    BuiltIn.Should_Be_Equal_As_Integers    0    ${ise_port_occupied}

Check_Ise_Harvest_Status
    [Arguments]    ${ise_harvest_status_json}    ${expected_templates_amount}
    [Documentation]    Check ise harvest status by templatest written amount
    ${templates_written}    BuiltIn.Set_Variable    ${ise_harvest_status_json['gbp-sxp-ise-adapter']['ise-harvest-status']['templates-written']}
    BuiltIn.Should_Be_Equal_As_Integers    ${expected_templates_amount}    ${templates_written}

Clean_ise_source_config
    [Documentation]    Wipe clean ise source configuration
    BuiltIn.Run_Keyword_And_Ignore_Error    Remove All Elements If Exist    ${SXP_ISE_ADAPTER_CONFIG_URI}

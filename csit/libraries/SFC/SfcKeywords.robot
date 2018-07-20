*** Settings ***

*** Variables ***

*** Keywords ***
Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp} =    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp} =    RequestsLibrary.Get Request    session    ${uri}
    [Return]    ${resp.json()}

Check Classifier Flows
    ${flowList} =    DockerSfc.Get Flows In Docker Containers
    log    ${flowList}
    Should Contain Match    ${flowList}    *actions=pop_nsh*
    Should Contain Match    ${flowList}    *actions=push_nsh*

Check Service Function Types Added
    [Arguments]    ${elements}
    [Documentation]    Check that the service function types are updated with the service function names
    Check For Elements At URI    ${SERVICE_FUNCTION_TYPES_URI}    ${elements}

Check Service Function Types Removed
    [Arguments]    ${elements}
    [Documentation]    Check that the service function names are removed from the service function types
    Check For Elements Not At URI    ${SERVICE_FUNCTION_TYPES_URI}    ${elements}

Check Empty Service Function Paths State
    [Documentation]    Check that the service function paths state is empty after deleting SFPs
    Check For Specific Number Of Elements At URI    ${SERVICE_FUNCTION_PATHS_STATE_URI}    service-function-path-state    0

Check Rendered Service Path Created
    [Arguments]    ${sfp_name}
    [Documentation]    Check that the Rendered Service Path is created
    ${sfp_name_elements_list} =    Create List    ${sfp_name}
    Check For Elements At URI    ${SERVICE_FUNCTION_PATHS_STATE_URI}    ${sfp_name_elements_list}

Check Rendered Service Path Deleted
    [Arguments]    ${sfp_name}
    [Documentation]    Check that the Rendered Service Path is deleted
    ${sfp_name_elements_list} =    Create List    ${sfp_name}
    Check For Elements Not At URI    ${SERVICE_FUNCTION_PATHS_STATE_URI}    ${sfp_name_elements_list}

Get Rendered Service Path Name
    [Arguments]    ${sfp_name}    ${get_reverse}=False
    [Documentation]    Given an SFP name, do a get on ${SERVICE_FUNCTION_PATH_STATE_URI} to get the RSP name
    ${resp} =    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATH_STATE_URI}${sfp_name}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    # should be like this: {"service-function-path-state":[{"name":"SFC1-100","sfp-rendered-service-path":[{"name":"SFC1-100-Path-183"}]}]}
    ${sfp_rendered_service_path_list} =    Collections.Get_From_Dictionary    ${resp.json()}    service-function-path-state
    ${sfp_rendered_service_path_dict} =    Collections.Get_From_List    ${sfp_rendered_service_path_list}    0
    ${sfp_state_list} =    Collections.Get_From_Dictionary    ${sfp_rendered_service_path_dict}    sfp-rendered-service-path
    ${list_length} =    Get Length    ${sfp_state_list}
    # The "sfp-rendered-service-path" will only have 1 or 2 entries, depending on chain symmetry config.
    # The RSP name will be "<SfpName>-Path-<PathId>" and the optional symmetric name will be <SfpName>-Path-<PathId>-Reverse"
    ${value} =    Set Variable    None
    : FOR    ${i}    IN RANGE    ${list_length}
    \    ${rsp_name_dict} =    Get From List    ${sfp_state_list}    ${i}
    \    ${name} =    Collections.Get_From_Dictionary    ${rsp_name_dict}    name
    \    @{matches} =    String.Get Regexp Matches    ${name}    .*Reverse$
    \    ${matches_length} =    BuiltIn.Get Length    ${matches}
    \    ${value} =    Set Variable If    "${get_reverse}" == "False" and 0 == ${matches_length}    ${name}    "${get_reverse}" == "True" and 0 < ${matches_length}    ${name}
    \    ...    "${value}" != "None"    ${value}
    [Return]    ${value}

Create Sfp And Wait For Rsp Creation
    [Arguments]    ${sfp_file_name}    ${created_sfps}
    [Documentation]    Given an SFP name, create it and wait for the associated RSPs to be created
    Add Elements To URI From File And Verify    ${SERVICE_FUNCTION_PATHS_URI}    ${sfp_file_name}
    Run Keyword If    len(${created_sfps}) > 0    Wait Until Keyword Succeeds    60s    2s    Check For Elements At URI    ${SERVICE_FUNCTION_PATHS_STATE_URI}
    ...    ${created_sfps}

Delete Sfp And Wait For Rsps Deletion
    [Arguments]    ${sfp_name}
    [Documentation]    Given an SFP name, delete it and wait for the associated SFP state and RSPs to be deleted
    Remove All Elements At URI And Verify    ${SERVICE_FUNCTION_PATH_URI}${sfp_name}
    Wait Until Keyword Succeeds    60s    2s    Check Rendered Service Path Deleted    ${sfp_name}

Delete All Sfps And Wait For Rsps Deletion
    [Documentation]    Delete all SFPs and wait for the RSPs to be deleted
    Remove All Elements At URI And Verify    ${SERVICE_FUNCTION_PATHS_URI}
    Wait Until Keyword Succeeds    60s    2s    Check Empty Service Function Paths State

Switch Ips In Json Files
    [Arguments]    ${json_dir}    ${container_names}
    ${normalized_dir}=    OperatingSystem.Normalize Path    ${json_dir}/*.json
    : FOR    ${cont_name}    IN    @{container_names}
    \    ${cont_ip} =    Get Docker IP    ${cont_name}
    \    OperatingSystem.Run    sudo sed -i 's/${cont_name}/${cont_ip}/g' ${normalized_dir}

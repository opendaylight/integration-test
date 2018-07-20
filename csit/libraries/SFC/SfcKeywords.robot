*** Settings ***

*** Variables ***

*** Keywords ***
Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.Get Request    session    ${uri}
    [Return]    ${resp.json()}

Check Classifier Flows
    ${flowList}=    DockerSfc.Get Flows In Docker Containers
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
    Check For Elements At URI    ${SERVICE_FUNCTION_PATHS_STATE_URI}    ${sfp_name}

Check Rendered Service Path Deleted
    [Arguments]    ${sfp_name}
    [Documentation]    Check that the Rendered Service Path is deleted
    ${sfp_name_elements_list} =    Create List    ${sfp_name}
    Check For Elements Not At URI    ${SERVICE_FUNCTION_PATHS_STATE_URI}    ${sfp_name_elements_list}

Get Rendered Service Path Name
    [Arguments]    ${sfp_name}    ${get_reverse}=False
    [Documentation]    Given an SFP name, do a get on ${SERVICE_FUNCTION_PATH_STATE_URI} to get the RSP name
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATH_STATE_URI}${sfp_name}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    # TODO this log statement is temporary
    BuiltIn.Log    ${resp.content}
    ${sfp_state_list} =    Collections.Get_From_Dictionary    ${resp.json()}[service-function-path-state][0]    key=sfp-rendered-service-path
    # TODO this log statement is temporary
    BuiltIn.Log    ${sfp_state_list}
    ${list_length} =    Get Length    ${sfp_state_list}
    # The "sfp-rendered-service-path" will only have 1 or 2 entries, depending on chain symmetry config.
    # The RSP name will be "<SfpName>-Path-<PathId>" and the optional symmetric name will be <SfpName>-Path-<PathId>-Reverse"
    ${value} =    Set Variable    None
    : FOR    ${i}    IN RANGE    ${list_length}
    \    ${sfp_state_dict} =    Get From List    ${sfp_state_list}    ${i}
    \    ${name} =    &{sfp_state_dict}[name]
    \    @{matches} =    String.Get Regexp Matches    ${name}    .*Reverse$
    \    ${matches_length} =    BuiltIn.Get Length    ${matches}
    \    Run Keyword If    "${get_reverse}" == "False"    Set Variable If    ${matches_length} == 0    ${name}    ${value}
    \    Run Keyword If    "${get_reverse}" == "True"    Set Variable If    ${matches_length} > 0    ${name}    ${value}
    [Return]    ${value}

Create Sfp And Wait For Rsp Creation
    [Arguments]    ${sfp_file_name}    ${created_rsps}
    [Documentation]    Given an SFP name, create it and wait for the associated RSPs to be created
    Add Elements To URI From File And Verify    ${SERVICE_FUNCTION_PATHS_URI}    ${sfp_file_name}
    ${created_rsps} =    Create List    "SFC1-100"    "SFC1-200"    "SFC1-300"    "SFC2-100"    "SFC1-200"
    ${created_rsps_length} =    BuiltIn.Get Length    ${created_rsps}
    Run Keyword If    "${created_rsps_length}" > "0"    Wait Until Keyword Succeeds    60s    2s    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}
    ...    ${created_rsps}

Delete Sfp And Wait For Rsps Deletion
    [Arguments]    ${sfp_name}
    [Documentation]    Given an SFP name, delete it and wait for the associated SFP state and RSPs to be deleted
    Remove All Elements At URI And Verify    ${SERVICE_FUNCTION_PATH_URI}${sfp_name}
    Wait Until Keyword Succeeds    60s    2s    Check Rendered Service Path Deleted    ${sfp_name}
    # Now verify that the RSP no longer exists
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp_name}
    Should Be Equal As Strings    ${resp.status_code}    404

Switch Ips In Json Files
    [Arguments]    ${json_dir}    ${container_names}
    ${normalized_dir}=    OperatingSystem.Normalize Path    ${json_dir}/*.json
    : FOR    ${cont_name}    IN    @{container_names}
    \    ${cont_ip}=    Get Docker IP    ${cont_name}
    \    OperatingSystem.Run    sudo sed -i 's/${cont_name}/${cont_ip}/g' ${normalized_dir}

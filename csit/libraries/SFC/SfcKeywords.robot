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
    ${value}    To Json    ${resp.content}
    [Return]    ${value}

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
    Check For Elements Not At URI    ${SERVICE_FUNCTION_PATHS_STATE_URI}    ${sfp_name}

Get Rendered Service Path Name
    [Arguments]    ${sfp_name} ${get_reverse}=False
    [Documentation]    Given an SFP name, do a get on ${SERVICE_FUNCTION_TYPES_URI} to get the RSP name
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_TYPES_URI}service-function-path-state/${sfp_name}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${json} =    RequestsLibrary.To_Json    ${resp.content}
    ${sfp_state_list} =    Collections.Get_From_Dictionary    ${json}    key=sfp-rendered-service-path
    ${list_length} =    Get Length    ${sfp_state_list}
    # The "sfp-rendered-service-path" will only have 1 or 2 entries, depending on chain symmetry config.
    # The RSP name will be "<SfpName>-Path-<PathId>" and the optional symmetric name will be <SfpName>-Path-<PathId>-Reverse"
    ${value} =    Set Variable    None
    : FOR    ${i}    IN RANGE    ${list_length}
    \    ${dictionary} =    Get From List    ${dictionary_list}    ${i}
    \    ${name} =    &{dictionary}[name]
    \    @{matches} =    String.Get Regexp Matches    ${name}    .*Reverse$
    \    ${matches_length} =    BuiltIn.Get Length    ${matches}
    \    Run Keyword If    "${get_reverse}" == "False"    Set Variable If    ${matches_length} == 0    ${name}    ${value}
    \    Run Keyword If    "${get_reverse}" == "True"    Set Variable If    ${matches_length} > 0    ${name}    ${value}
    [Return]    ${value}

Switch Ips In Json Files
    [Arguments]    ${json_dir}    ${container_names}
    ${normalized_dir}=    OperatingSystem.Normalize Path    ${json_dir}/*.json
    : FOR    ${cont_name}    IN    @{container_names}
    \    ${cont_ip}=    Get Docker IP    ${cont_name}
    \    OperatingSystem.Run    sudo sed -i 's/${cont_name}/${cont_ip}/g' ${normalized_dir}

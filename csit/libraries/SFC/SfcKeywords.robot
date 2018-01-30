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

Switch Ips In Json Files
    [Arguments]    ${json_dir}    ${container_names}
    ${normalized_dir}=    OperatingSystem.Normalize Path    ${json_dir}/*.json
    : FOR    ${cont_name}    IN    @{container_names}
    \    ${cont_ip}=    Get Docker IP    ${cont_name}
    \    OperatingSystem.Run    sudo sed -i 's/${cont_name}/${cont_ip}/g' ${normalized_dir}

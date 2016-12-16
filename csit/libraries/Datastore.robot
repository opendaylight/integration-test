*** Settings ***
Library           OperatingSystem
Library           RequestsLibrary
Library           String

*** Variables ***
${project_dump_dir}    collect_dumps

*** Keywords ***
Get Model Dump
    [Arguments]    ${dump_file_name}    ${controller_ip}
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    ${contents}    Get File    ${project_dump_dir}/${dump_file_name}.txt
    @{data_models}    Split to lines    ${contents}
    Create Session    model_dump_session    http://${controller_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    : FOR    ${model}    IN    @{data_models}
    \    ${resp}=    RequestsLibrary.Get Request    model_dump_session    restconf/${model}
    \    Log    ${resp.status_code}
    \    ${pretty_output}=    To Json    ${resp.content}    pretty_print=True
    \    Log    ${pretty_output}

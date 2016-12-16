*** Settings ***
Library           RequestsLibrary
Variables         ../variables/netvirt/Modules.py

*** Keywords ***
Get Model Dump
    [Arguments]    ${controller_ip}
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    Create Session    model_dump_session    http://${controller_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    : FOR    ${model}    IN    @{data_models}
    \    ${resp}=    RequestsLibrary.Get Request    model_dump_session    restconf/${model}
    \    Log    ${resp.status_code}
    \    ${pretty_output}=    To Json    ${resp.content}    pretty_print=True
    \    Log    ${pretty_output}

*** Settings ***
Documentation     Library to deal with mdsal data models. Initially, as a common place to show and
...               debug a list of data models.
Library           RequestsLibrary

*** Variables ***
@{data_models}    ${EMPTY}

*** Keywords ***
Get Model Dump
    [Arguments]    ${controller_ip}    ${data_models}=@{data_models}
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    # while feature request in bug 7892 is not done, we will quickly timeout and not retry the model dump get
    # request. This is because when it's done in a failed cluster state, it could take 20s for the reesponse to
    # to come back as the internal clustering times out waiting for a leader which will not come. When bug 7892
    # is resolved, we can remove the timeout=1 and max_retries=0, but likely have to modify the request itself to
    # pass a timeout to restconf
    Create Session    model_dump_session    http://${controller_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=1    max_retries=0
    : FOR    ${model}    IN    @{data_models}
    \    ${resp}=    RequestsLibrary.Get Request    model_dump_session    restconf/${model}
    \    Log    ${resp.status_code}
    \    ${pretty_output}=    To Json    ${resp.content}    pretty_print=True
    \    Log    ${pretty_output}

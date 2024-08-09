*** Settings ***
Documentation       Library to deal with mdsal data models. Initially, as a common place to show and
...                 debug a list of data models.

Library             RequestsLibrary
Resource            Utils.robot


*** Variables ***
@{internal_data_models}     ${EMPTY}
${DISPATCHER_TABLE}         17
${INTEGRATION_BRIDGE}       br-int


*** Keywords ***
Get Model Dump
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    [Arguments]    ${controller_ip}    ${data_models}=@{internal_data_models}    ${restconf_root}=rests
    # while feature request in bug 7892 is not done, we will quickly timeout and not retry the model dump get
    # request. This is because when it's done in a failed cluster state, it could take 20s for the reesponse to
    # to come back as the internal clustering times out waiting for a leader which will not come. When bug 7892
    # is resolved, we can remove the timeout=1 and max_retries=0, but likely have to modify the request itself to
    # pass a timeout to restconf
    Create Session
    ...    model_dump_session
    ...    http://${controller_ip}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${HEADERS}
    ...    timeout=1
    ...    max_retries=0
    FOR    ${model}    IN    @{data_models}
        ${resp}=    RequestsLibrary.GET On Session    model_dump_session    url=${restconf_root}/${model}
        Utils.Log Content    ${resp.text}
    END

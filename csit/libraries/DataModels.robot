*** Settings ***
Documentation     Library to deal with mdsal data models. Initially, as a common place to show and
...               debug a list of data models.
Library           RequestsLibrary
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
@{internal_data_models}    ${EMPTY}

*** Keywords ***
Get Model Dump
    [Arguments]    ${controller_ip}    ${data_models}=@{internal_data_models}
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    # while feature request in bug 7892 is not done, we will quickly timeout and not retry the model dump get
    # request. This is because when it's done in a failed cluster state, it could take 20s for the reesponse to
    # to come back as the internal clustering times out waiting for a leader which will not come. When bug 7892
    # is resolved, we can remove the timeout=1 and max_retries=0, but likely have to modify the request itself to
    # pass a timeout to restconf
    Create Session    model_dump_session    http://${controller_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=1    max_retries=0
    FOR    ${model}    IN    @{data_models}
        ${resp}=    RequestsLibrary.GET On Session    model_dump_session    restconf/${model}
        ${pretty_output}=    To Json    ${resp.text}    pretty_print=True
        Log    ${pretty_output}
    END

Verify No Ingress Dispatcher Non-Default Flow Entries
    [Arguments]    ${ovs_ip}
    [Documentation]    Verify the ingress dispatcher table has no non-default flows after neutron was cleaned up
    ${flow_output}=    Run Command On Remote System    ${ovs_ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE} table=${DISPATCHER_TABLE} | grep -v "priority=0"
    Log    ${flow_output}
    #Should Not Contain    ${flow_output}    table=${DISPATCHER_TABLE} # Skipping test verification until bug 7451 is resolved

Verify Flows Are Cleaned Up On All OpenStack Nodes
    [Documentation]    Verify flows are cleaned up from all OpenStack nodes
    FOR    ${ip}    IN    @{OS_ALL_IPS}
        Run Keyword And Continue On Failure    Verify No Ingress Dispatcher Non-Default Flow Entries    ${ip}
    END

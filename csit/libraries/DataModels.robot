*** Settings ***
Documentation     Library to deal with mdsal data models. Initially, as a common place to show and
...               debug a list of data models.
Library           RequestsLibrary

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
    : FOR    ${model}    IN    @{data_models}
    \    ${resp}=    RequestsLibrary.Get Request    model_dump_session    restconf/${model}
    \    ${pretty_output}=    To Json    ${resp.content}    pretty_print=True
    \    Log    ${pretty_output}

Verify No Ingress Dispatcher Non-Default Flow Entries
    [Arguments]    ${ovs_ip}
    [Documentation]    Verify the ingress dispatcher table has no non-default flows after neutron was cleaned up
    ${flow_output}=    Run Command On Remote System    ${ovs_ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int table=${DISPATCHER_TABLE} | grep -v "priority=0"
    Log    ${flow_output}
    #Should Not Contain    ${flow_output}    table=${DISPATCHER_TABLE} # Skipping test verification until bug 7451 is resolved

Save Flows
    [Arguments]    ${ovs_ip}
    [Documentation]    Save Flows
    ${flow_output} =    Run Command On Remote System    ${ovs_ip}    ovs-ofctl -O OpenFlow13 dump-flows br-int |sed 's/cookie=\S\+\s\+duration=\S\+\s\+\(.*\)n_packets=\S\+\s\+n_bytes=\S\+\s\(.*\)/\1 \2/g'|grep -v idle_timeout
    Log    ${flow_output}
    [Return]    ${flow_output}

Verify Flows Are Cleaned Up On All OpenStack Nodes
    [Documentation]    Verify flows are cleaned up from all OpenStack nodes
    Run Keyword And Continue On Failure    Verify No Ingress Dispatcher Non-Default Flow Entries    ${OS_CONTROL_NODE_IP}
    Run Keyword And Continue On Failure    Verify No Ingress Dispatcher Non-Default Flow Entries    ${OS_COMPUTE_1_IP}
    Run Keyword And Continue On Failure    Verify No Ingress Dispatcher Non-Default Flow Entries    ${OS_COMPUTE_2_IP}

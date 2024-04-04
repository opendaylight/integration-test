*** Settings ***
Documentation       Test suite to test various rcp calls

Library             XML
Library             RequestsLibrary
Library             SSHLibrary
Resource            ../../../libraries/Utils.robot
Resource            ../../../libraries/FlowLib.robot
Variables           ../../../variables/ofplugin/RpcVariables.py

Suite Setup         Initialization Phase
Suite Teardown      Final Phase


*** Variables ***
${send_barrier_url}     /rests/operations/flow-capable-transaction:send-barrier
${send_echo_url}        /rests/operations/sal-echo:send-echo


*** Test Cases ***
Sending Barrier
    [Documentation]    Test to send barrier
    ${resp}=    RequestsLibrary.POST On Session
    ...    session
    ...    url=${send_barrier_url}
    ...    data=${RPC_SEND_BARRIER_DATA}
    ...    headers=${HEADERS_XML}
    ...    expected_status=200
    Log    ${resp.content}

Sending Echo
    [Documentation]    Test to send echo
    ${resp}=    RequestsLibrary.POST On Session
    ...    session
    ...    url=${send_echo_url}
    ...    data=${RPC_SEND_ECHO_DATA}
    ...    headers=${HEADERS_XML}
    ...    expected_status=200
    Log    ${resp.content}


*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational ds
    Start Mininet
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Switches In Topology    1

Final Phase
    [Documentation]    Stops mininet
    Stop Mininet
    Delete All Sessions

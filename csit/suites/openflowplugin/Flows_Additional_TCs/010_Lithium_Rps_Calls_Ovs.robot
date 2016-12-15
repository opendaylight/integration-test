*** Settings ***
Documentation     Test suite to test various rcp calls
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/FlowLib.robot
Variables         ../../../variables/ofplugin/RpcVariables.py

*** Variables ***
${send_barrier_url}    /restconf/operations/flow-capable-transaction:send-barrier
${send_echo_url}    /restconf/operations/sal-echo:send-echo

*** Test Cases ***
Sending Barrier
    [Documentation]    Test to send barrier
    ${resp}=    RequestsLibrary.Post Request    session    ${send_barrier_url}    data=${RPC_SEND_BARRIER_DATA}    headers=${HEADERS_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Sending Echo
    [Documentation]    Test to send echo
    ${resp}=    RequestsLibrary.Post Request    session    ${send_echo_url}    data=${RPC_SEND_ECHO_DATA}    headers=${HEADERS_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

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

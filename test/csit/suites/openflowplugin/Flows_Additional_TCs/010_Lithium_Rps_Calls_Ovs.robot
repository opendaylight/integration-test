*** Settings ***
Documentation     Test suite to test various rcp calls
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/Utils.txt
Variables         ../../../variables/ofplugin/RpcVariables.py

*** Variables ***
${send_barrier_url}    /restconf/operations/flow-capable-transaction:send-barrier
${send_echo_url}    /restconf/operations/sal-echo:send-echo

*** Test Cases ***
Sending Barrier
    [Documentation]    Test to send barrier
    ${resp}=    RequestsLibrary.Post    session    ${send_barrier_url}    data=${RPC_SEND_BARRIER_DATA}    headers=${HEADERS_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Sending Echo
    [Documentation]    Test to send echo
    ${resp}=    RequestsLibrary.Post    session    ${send_echo_url}    data=${RPC_SEND_ECHO_DATA}    headers=${HEADERS_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational ds
    Start Suite
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

Final Phase
    [Documentation]    Stops mininet
    Stop Suite
    Delete All Sessions

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    1

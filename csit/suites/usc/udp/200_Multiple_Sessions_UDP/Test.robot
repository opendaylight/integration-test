*** Settings ***
Documentation       Test suite for multiple sessions in an USC TLS channel

Library             Collections
Library             OperatingSystem
Library             SSHLibrary
Library             RequestsLibrary
Library             json
Library             ../../../../libraries/Common.py
Variables           ../../../../variables/Variables.py
Resource            ../../../../libraries/UscUtils.robot

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions
Test Timeout        1min


*** Test Cases ***
Add Channel
    [Documentation]    Add multiple USC DTLS channels
    FOR    ${port_index}    IN    @{LIST_ECHO_SERVER_PORT}
        ${content}    Create Dictionary
        ...    hostname=${TOOLS_SYSTEM_IP}
        ...    port=${port_index}
        ...    tcp=false
        ...    remote=false
        ${channel}    Create Dictionary    channel=${content}
        ${input}    Create Dictionary    input=${channel}
        ${data}    json.dumps    ${input}
        ${resp}    Post Request    session    ${REST_ADD_CHANNEL}    data=${data}
        Log    ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200
        Should Contain    ${resp.content}    Succeed to connect
    END

Check added Channel
    [Documentation]    Check if the channels are correct
    ${topo}    Create Dictionary    topology-id=usc
    ${input}    Create Dictionary    input=${topo}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_VIEW_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "topology"
    ${len}    Get Length    ${LIST_ECHO_SERVER_PORT}
    Should Contain    ${resp.content}    "sessions":${len}
    Should Contain    ${resp.content}    "channel-type":"DTLS"

Send Messages
    [Documentation]    Send test messages multiple times
    FOR    ${port_index}    IN    @{LIST_ECHO_SERVER_PORT}
        ${content}    Create Dictionary
        ...    hostname=${TOOLS_SYSTEM_IP}
        ...    port=${port_index}
        ...    tcp=false
        ...    content=${TEST_MESSAGE}
        ${channel}    Create Dictionary    channel=${content}
        ${input}    Create Dictionary    input=${channel}
        Send Now    ${input}
    END

View Bytes In and Bytes Out
    [Documentation]    Check if the number of Bytes In and Bytes Out are correct
    ${topo}    Create Dictionary    topology-id=usc
    ${input}    Create Dictionary    input=${topo}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_VIEW_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "topology"
    ${len}    Get Length    ${TEST_MESSAGE}
    ${len1}    Get Length    ${LIST_ECHO_SERVER_PORT}
    ${len2}    Get Length    ${TEST_MESSAGE}
    ${totalLen}    Evaluate    ${len1} * ${len2} * ${NUM_OF_MESSAGES}
    Should Contain    ${resp.content}    "bytes-out":${totalLen}
    Should Contain    ${resp.content}    "bytes-in":${totalLen}

Remove Sessions
    [Documentation]    Remove the channels
    FOR    ${port_index}    IN    @{LIST_ECHO_SERVER_PORT}
        ${content}    Create Dictionary    hostname=${TOOLS_SYSTEM_IP}    port=${port_index}    tcp=false
        ${channel}    Create Dictionary    channel=${content}
        ${input}    Create Dictionary    input=${channel}
        ${data}    json.dumps    ${input}
        ${resp}    Post Request    session    ${REST_REMOVE_SESSION}    data=${data}
        Log    ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200
        Should Contain    ${resp.content}    Succeed to remove
    END

Remove Channel
    [Documentation]    Remove the channels
    ${content}    Create Dictionary    hostname=${TOOLS_SYSTEM_IP}    tcp=false
    ${channel}    Create Dictionary    channel=${content}
    ${input}    Create Dictionary    input=${channel}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_REMOVE_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    Succeed to remove

Check Channel
    [Documentation]    Check if the channels are correct
    ${topo}    Create Dictionary    topology-id=usc
    ${input}    Create Dictionary    input=${topo}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_VIEW_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "topology"


*** Keywords ***
Send Now
    [Arguments]    ${body}
    FOR    ${index}    IN RANGE    0    ${NUM_OF_MESSAGES}
        ${data}    json.dumps    ${body}
        ${resp}    Post Request    session    ${REST_SEND_MESSAGE}    data=${data}
        Should Be Equal As Strings    ${resp.status_code}    200
        Should Contain    ${resp.content}    Succeed to send request
    END

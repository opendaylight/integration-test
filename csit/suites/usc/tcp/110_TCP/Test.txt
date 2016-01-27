*** Settings ***
Documentation     Test suite for an USC TLS channel
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           OperatingSystem
Library           SSHLibrary
Library           RequestsLibrary
Library           json
Library           ../../../../libraries/Common.py
Variables         ../../../../variables/Variables.py
Resource          ../../../../libraries/UscUtils.robot

*** Test Cases ***
Add Channel
    [Documentation]    Add an USC TLS channel
    ${content}    Create Dictionary    hostname=${TOOLS_SYSTEM_IP}    tcp=true    port=${ECHO_SERVER_PORT}    remote=false
    ${channel}    Create Dictionary    channel=${content}
    ${input}    Create Dictionary    input=${channel}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_ADD_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    Succeed to connect

Check added Channel
    [Documentation]    Check if the channel is correct
    ${topo}    Create Dictionary    topology-id=usc
    ${input}    Create Dictionary    input=${topo}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_VIEW_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    topology
    Should Contain    ${resp.content}    "sessions":1
    Should Contain    ${resp.content}    "channel-type":"TLS"

Send Messages
    [Documentation]    Send test messages multiple times to multiple sessions
    ${content}    Create Dictionary    hostname=${TOOLS_SYSTEM_IP}    port=${ECHO_SERVER_PORT}    tcp=true    content=${TEST_MESSAGE}
    ${channel}    Create Dictionary    channel=${content}
    ${input}    Create Dictionary    input=${channel}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_MESSAGES}
    \    ${data}    json.dumps    ${input}
    \    ${resp}    Post Request    session    ${REST_SEND_MESSAGE}    data=${data}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    Should Contain    ${resp.content}    Succeed to send request

View Bytes In and Bytes Out
    [Documentation]    Check if the number of Bytes In and Bytes Out are correct
    ${topo}    Create Dictionary    topology-id=usc
    ${input}    Create Dictionary    input=${topo}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_VIEW_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    topology
    ${len}    Get Length    ${TEST_MESSAGE}
    ${totalLen}    Evaluate    ${len} * ${NUM_OF_MESSAGES}
    Should Contain    ${resp.content}    "bytes-out":${totalLen}
    Should Contain    ${resp.content}    "bytes-in":${totalLen}

Remove Channel
    [Documentation]    Remove the channel
    ${content}    Create Dictionary    hostname=${TOOLS_SYSTEM_IP}    port=${ECHO_SERVER_PORT}    tcp=true
    ${channel}    Create Dictionary    channel=${content}
    ${input}    Create Dictionary    input=${channel}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_REMOVE_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    Succeed to remove

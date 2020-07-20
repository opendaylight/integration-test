*** Settings ***
Documentation     RFC8040 notifications via SSE tests
...
...               Copyright (c) 2020 Lumina Networks, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs RFC8040 Notifications via SSE for data store notifications.
...
...               This suite uses inventory (config part) as an area to make dummy writes into,
...               just to trigger data change listener to produce a notification.
...               Openflowplugin may have some data there, and before Boron, netconf-connector
...               was also exposing some data in inventory.
...
...               To avoid unexpected responses, this suite depetes all data from config inventory,
...               so this suite should not be followed by any suite expecting default data there.
...
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary    timeout=10s
Library           XML
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/Restconf.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${TEMPLATE_FOLDER}    ${CURDIR}/templates
${RFC8040_SSE_SUBSCRIBE_URI}    rests/operations/sal-remote:create-data-change-event-subscription
${RESTCONF_SUBSCRIBE_DATA}    subscribe.xml
${NODES_STREAM_PATH}    opendaylight-inventory:nodes/datastore=CONFIGURATION/scope=BASE
${RFC8040_NOTIFICATIONS_STREAMS_URI}    rests/data/ietf-restconf-monitoring:restconf-state/streams
${RFC8040_GET_SUBSCRIPTION_URI}    ${RFC8040_NOTIFICATIONS_STREAMS_URI}/stream/data-change-event-subscription/${NODES_STREAM_PATH}
${RFC8040_GET_SSE_URI}    rests/notif/data-change-event-subscription/${NODES_STREAM_PATH}
${RFC8040_DELETE_SSE_URI}    rests/data/opendaylight-inventory:nodes?content=config
${RESTCONF_CONFIG_DATA}    config_data.xml
${RESTCONF_CONFIG_DATA_2}    config_data_updated.xml
${CONTROLLER_LOG_LEVEL}    INFO
${SSE_RECEIVER_LOG_FILE}    ssereceiver.log


*** Test Cases ***
Create_Data_Change_Event_Subscription
    [Documentation]    Create data change event subscription
    [Tags]    critical
    # check get streams url passes prior to creating a subscription
    ${resp} =    RequestsLibrary.Get_Request    restconf    ${RFC8040_NOTIFICATIONS_STREAMS_URI}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${body} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_SUBSCRIBE_DATA}
    BuiltIn.Log    ${RFC8040_SSE_SUBSCRIBE_URI}
    BuiltIn.Log    ${body}
    ${uri} =    Restconf.Generate URI    sal-remote:create-data-change-event-subscription    rpc
    ${resp} =    RequestsLibrary.Post_Request    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get_Data_Change_Event_Subscription
    [Documentation]    Get & check data change event subscription ...
    [Tags]    critical
    ${resp} =    RequestsLibrary.Get_Request    restconf    ${RFC8040_GET_SUBSCRIPTION_URI}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${location} =    XML.Get Element Text    ${resp.content}
    BuiltIn.Log    ${location}
    Set Suite Variable    ${location}

Start_Receiver
    [Documentation]    Start the sse listener
    [Tags]    critical
    ${output} =    SSHLibrary.Write    python3 ssereceiver.py --controller ${ODL_SYSTEM_IP} --logfile ${SSE_RECEIVER_LOG_FILE}
    BuiltIn.Log    ${output}
    ${output} =    SSHLibrary.Read    delay=2s
    BuiltIn.Log    ${output}
    Should Contain    ${output}    Starting to receive server-sent event messages

Change_Config
    [Documentation]    Make a change in configuration.
    [Tags]    critical
    ${body} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA_2}
    BuiltIn.Log    ${body}
    ${resp} =    RequestsLibrary.Post_Request    restconf    rests/data    headers=${SEND_ACCEPT_XML_HEADERS}    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${uri} =    Restconf.Generate URI    opendaylight-inventory:nodes    config

Check_Create_Notification
    [Documentation]    Check the listener log for a change notification.
    [Tags]    critical
    Sleep    60s
    ${notification} =    SSHLibrary.Execute_Command    cat ${SSE_RECEIVER_LOG_FILE}
    BuiltIn.Log    ${notification}
    BuiltIn.Set_Suite_Variable    ${notification}
    BuiltIn.Should_Contain    ${notification}    <notification xmlns=
    BuiltIn.Should_Contain    ${notification}    <eventTime>
    BuiltIn.Should_Contain    ${notification}    <data-changed-notification xmlns=
    BuiltIn.Should_Contain    ${notification}    <operation>created</operation>
    BuiltIn.Should_Contain    ${notification}    </data-change-event>
    BuiltIn.Should_Contain    ${notification}    </data-changed-notification>
    BuiltIn.Should_Contain    ${notification}    </notification>

Delete_Data_Change_Notification_And_Check
    [Documentation]    Check the websocket listener log for a delete notification.
    [Tags]    critical
    ${resp} =    RequestsLibrary.Delete_Request    restconf    ${RFC8040_DELETE_SSE_URI}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    # WUKS on output log file to check operation deleted
    Sleep    60s
    ${sse_log}=    OperatingSystem.Get File    ${SSE_RECEIVER_LOG_FILE}
    BuiltIn.Should_Contain    ${sse_log}    <operation>deleted</operation>

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=receiver
    SSHKeywords.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/ssereceiver.py
    SSHLibrary.Execute Command    sudo python3 -m pip install asyncio aiohttp aiohttp-sse-client coroutine
    RequestsLibrary.Create Session    restconf    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    BuiltIn.Log    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    ${uri} =    Restconf.Generate URI    opendaylight-inventory:nodes    config
    TemplatedRequests.Delete_From_Uri    uri=${uri}    additional_allowed_status_codes=${DELETED_STATUS_CODES}

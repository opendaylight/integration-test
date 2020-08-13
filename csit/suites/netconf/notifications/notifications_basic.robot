*** Settings ***
Documentation     Basic tests for BGP application peer.
...           
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...           
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...           
...               Test suite performs basic subscribtion case for data store notifications.
...               For procedure description see the
...               https://wiki.opendaylight.org/view/OpenDaylight_Controller:MD-SAL:Restconf:Change_event_notification_subscription
...           
...           
...               This suite uses inventory (config part) as an area to make dummy writes into,
...               just to trigger data change listener to produce a notification.
...               Openflowplugin may have some data there, and before Boron, netconf-connector
...               was also exposing some data in inventory.
...           
...               To avoid unexpected responses, this suite depetes all data from config inventory,
...               so this suite should not be followed by any suite expecting default data there.
...           
...               Covered bugs:
...               Bug 3934 - Websockets: Scope ONE doesn't work correctly
...           
...               TODO: Use cars/people model for data
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary    timeout=10s
Library           XML
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/Restconf.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource          ${CURDIR}/../../../variables/Variables.robot

*** Variables ***
${TEMPLATE_FOLDER}    ${CURDIR}/templates
${DRAFT_NOTIFICATIONS_STREAMS_URI}    restconf/streams
${RFC8040_NOTIFICATIONS_STREAMS_URI}    rests/data/ietf-restconf-monitoring:restconf-state/streams
${NODES_STREAM_PATH}    opendaylight-inventory:nodes/datastore=CONFIGURATION/scope=BASE
${DRAFT_GET_SUBSCRIPTION_URI}    ${DRAFT_NOTIFICATIONS_STREAMS_URI}/stream/data-change-event-subscription/${NODES_STREAM_PATH}
${RFC8040_GET_SUBSCRIPTION_URI}    ${RFC8040_NOTIFICATIONS_STREAMS_URI}/stream/data-change-event-subscription/${NODES_STREAM_PATH}
${RESTCONF_SUBSCRIBE_DATA}    subscribe.xml
${RESTCONF_CONFIG_DATA}    config_data.xml
${RECEIVER_LOG_FILE}    wsreceiver.log
${RECEIVER_OPTIONS}    ${EMPTY}
${CONTROLLER_LOG_LEVEL}    INFO

*** Test Cases ***
Subscribe_To_Yang_Notification
    [Documentation]    Subscribe to notification.
    [Tags]    critical
    Comment    Check notification streams. This only works for RFC 8040.
    ${resp} =    RequestsLibrary.Get_Request    restconf    ${RFC8040_NOTIFICATIONS_STREAMS_URI}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Comment    Subscribe to notification
    ${root}=    XML.Parse XML    ${resp.content}
    ${name}=    Get Elements Texts    ${root}    stream/name
    BuiltIn.Log    ${name[0]}
    ${uri} =    Set Variable If    "${USE_RFC8040}" == "False"    ${DRAFT_NOTIFICATIONS_STREAMS_URI}/netconf-config-change/JSON/location    ${RFC8040_NOTIFICATIONS_STREAMS_URI}/stream=${name[0]}/access=JSON/location
    ${resp} =    RequestsLibrary.Get_Request    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create_DCN_Subscription
    [Documentation]    Create DCN Subscription.
    [Tags]    critical
    Comment    Create DCN subscription
    ${body} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_SUBSCRIBE_DATA}
    ${uri} =    Restconf.Generate URI    sal-remote:create-data-change-event-subscription    rpc
    ${resp} =    RequestsLibrary.Post_Request    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Subscribe_To_DCN_Notifications
    [Documentation]    Subscribe to DCN notifications.
    [Tags]    critical
    ${uri} =    Set Variable If    "${USE_RFC8040}" == "False"    ${DRAFT_GET_SUBSCRIPTION_URI}    ${RFC8040_GET_SUBSCRIPTION_URI}
    ${resp} =    RequestsLibrary.Get_Request    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${location} =    XML.Get Element Text    ${resp.content}
    BuiltIn.Log    ${location}
    BuiltIn.Log    ${resp.headers["Location"]}
    Should Contain    ${location}    ${resp.headers["Location"]}
    BuiltIn.Set_Suite_Variable    ${location}

Start_Receiver
    [Documentation]    Start the websocket listener
    ${output} =    Run Keyword If    "${USE_RFC8040}" == "False"    SSHLibrary.Write    python wsreceiver.py --uri ${location} --count 2 --logfile ${RECEIVER_LOG_FILE} ${RECEIVER_OPTIONS}
    ...    ELSE    SSHLibrary.Write    python3 ssereceiver.py --controller ${ODL_SYSTEM_IP} --logfile ${RECEIVER_LOG_FILE}
    BuiltIn.Log    ${output}
    ${output} =    SSHLibrary.Read    delay=2s
    BuiltIn.Log    ${output}

Change_Config
    [Documentation]    Make a change in configuration.
    [Tags]    critical
    ${body} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA}
    ${uri} =    Set Variable If    "${USE_RFC8040}" == "False"    /restconf/config    /rests/data
    ${resp} =    RequestsLibrary.Post_Request    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${uri} =    Restconf.Generate URI    opendaylight-inventory:nodes    config
    ${resp} =    RequestsLibrary.Delete_Request    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Check_Create_Notification
    [Documentation]    Check the websocket listener log for a change notification.
    [Tags]    critical
    ${notification} =    SSHLibrary.Execute_Command    cat ${RECEIVER_LOG_FILE}
    BuiltIn.Log    ${notification}
    BuiltIn.Set_Suite_Variable    ${notification}
    BuiltIn.Should_Contain    ${notification}    <notification xmlns=
    BuiltIn.Should_Contain    ${notification}    <eventTime>
    BuiltIn.Should_Contain    ${notification}    <data-changed-notification xmlns=
    BuiltIn.Should_Contain    ${notification}    <operation>created</operation>
    BuiltIn.Should_Contain    ${notification}    </data-change-event>
    BuiltIn.Should_Contain    ${notification}    </data-changed-notification>
    BuiltIn.Should_Contain    ${notification}    </notification>

Check_Bug_3934
    [Documentation]    Check the websocket listener log for the bug correction.
    [Tags]    critical
    ${data} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA}
    BuiltIn.Log    ${data}
    BuiltIn.Log    ${notification}
    ${packed_data} =    String.Remove_String    ${data}    ${SPACE}
    ${packed_notification} =    String.Remove_String    ${notification}    ${SPACE}
    BuiltIn.Should_Contain    ${packed_notification}    ${packed_data}
    [Teardown]    Report_Failure_Due_To_Bug    3934

Check_Delete_Notification
    [Documentation]    Check the websocket listener log for a delete notification.
    [Tags]    critical
    BuiltIn.Should_Contain    ${notification}    <operation>deleted</operation>

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    SSHKeywords.Open_Connection_To_Tools_System
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/wsreceiver.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/ssereceiver.py
    SSHLibrary.Execute Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    SSHLibrary.Execute Command    sudo python3 -m pip install asyncio aiohttp aiohttp-sse-client coroutine
    SSHLibrary.Execute_Command    sudo pip install websocket-client
    ${output_log} =    SSHLibrary.Execute_Command    python -c "help('modules')"
    Should Contain    ${output_log}    websocket
    RequestsLibrary.Create Session    restconf    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}

Teardown_Everything
    [Documentation]    Close connections.
    ...    Tear down imported Resources.
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Log_Response
    [Arguments]    ${resp}
    [Documentation]    Log response.
    BuiltIn.Log    ${resp}
    BuiltIn.Log    ${resp.headers}
    BuiltIn.Log    ${resp.content}

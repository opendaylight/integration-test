*** Settings ***
Documentation     Basic tests for BGP application peer.
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
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/Restconf.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${TEMPLATE_FOLDER}    ${CURDIR}/templates
${RFC8040_SSE_SUBSCRIBE_URI}    rests/operations/sal-remote:create-data-change-event-subscription
${RESTCONF_SUBSCRIBE_DATA}    subscribe.xml
${NODES_STREAM_PATH}    opendaylight-inventory:nodes/datastore=CONFIGURATION/scope=BASE
${RFC8040_NOTIFICATIONS_STREAMS_URI}    rests/data/ietf-restconf-monitoring:restconf-state/streams
${RFC8040_GET_SUBSCRIPTION_URI}    ${RFC8040_NOTIFICATIONS_STREAMS_URI}/stream/data-change-event-subscription/${NODES_STREAM_PATH}
${RFC8040_GET_SSE_URI}    rests/notif/data-change-event-subscription/${NODES_STREAM_PATH}
${RESTCONF_CONFIG_DATA}    config_data.xml
${RESTCONF_CONFIG_DATA_2}    config_data_updated.xml
${CONTROLLER_LOG_LEVEL}    INFO

*** Test Cases ***
Clean_Config
    [Documentation]    Make sure config inventory is empty.
    [Tags]    critical
    ${uri} =    Restconf.Generate URI    opendaylight-inventory:nodes    config
    TemplatedRequests.Delete_From_Uri    uri=${uri}    additional_allowed_status_codes=${DELETED_STATUS_CODES}
    # TODO: Rework also other test cases to use TemplatedRequests.

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

Create_Data_Change_Event_Subscription
    [Documentation]    Get & check data change event subscription ...
    [Tags]    critical
    ${resp} =    RequestsLibrary.Get_Request    restconf    ${RFC8040_GET_SUBSCRIPTION_URI}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${location} =    XML.Get Element Text    ${resp.content}
    BuiltIn.Log    ${location}

Start_Data_Change_Event_Listener
    [Documentation]    Start the  listener
    ## write curl call bare then output to log file
    ${resp} =    RequestsLibrary.Get_Request    restconf    ${RFC8040_GET_SSE_URI}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

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

Delete_Data_Change_Notification_And_Check
    [Documentation]    Check the websocket listener log for a delete notification.
    [Tags]    critical
    ${resp} =    RequestsLibrary.Delete_Request    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    # WUKS on output log file to check operation deleted
    #BuiltIn.Should_Contain    ${notification}    <operation>deleted</operation>

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=receiver
    SSHKeywords.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/wsreceiver.py
    ${output_log}    ${error_log} =    SSHLibrary.Execute Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    BuiltIn.Log    ${output_log}
    BuiltIn.Log    ${error_log}
    ${output_log} =    SSHLibrary.Execute_Command    sudo pip install websocket-client
    BuiltIn.Log    ${output_log}
    ${output_log} =    SSHLibrary.Execute_Command    python -c "help('modules')"
    BuiltIn.Log    ${output_log}
    Should Contain    ${output_log}    websocket
    RequestsLibrary.Create Session    restconf    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    BuiltIn.Log    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
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

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
...               Covered bugs:
...               Bug 3934 - Websockets: Scope ONE doesn't work correctly
...
...               TODO: Use cars/people model for data
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           Collections
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${TEMPLATE_FOLDER}    ${CURDIR}/templates
${RESTCONF_SUBSCRIBE_URI}    restconf/operations/sal-remote:create-data-change-event-subscription
${RESTCONF_SUBSCRIBE_DATA}    subscribe.xml
${RESTCONF_GET_SUBSCRIPTION_URI}    restconf/streams/stream/opendaylight-inventory:nodes/datastore=CONFIGURATION/scope=BASE
${RESTCONF_CONFIG_URI}    restconf/config
${RESTCONF_CONFIG_DATA}    config_data.xml
${RECEIVER_LOG_FILE}    wsreceiver.log
${RECEIVER_OPTIONS}    ${EMPTY}
${CONTROLLER_LOG_LEVEL}    INFO

*** Test Cases ***
Clean_Config
    [Documentation]    Delete item in configuration.
    [Tags]    critical
    BuiltIn.Log    ${CONFIG_NODES_API}
    ${resp}=    RequestsLibrary.Delete_Request    restconf    ${CONFIG_NODES_API}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Be_Equal_As_Strings    ${resp.status_code}    200

Create_Subscribtion
    [Documentation]    Subscribe for notifications.
    [Tags]    critical
    ${body}=    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_SUBSCRIBE_DATA}
    BuiltIn.Log    ${RESTCONF_SUBSCRIBE_URI}
    BuiltIn.Log    ${body}
    ${resp}=    RequestsLibrary.Post_Request    restconf    ${RESTCONF_SUBSCRIBE_URI}    headers=${SEND_ACCEPT_XML_HEADERS}    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Be_Equal_As_Strings    ${resp.status_code}    200

Check_Subscribtion
    [Documentation]    Get & check subscribtion ...
    [Tags]    critical
    ${resp}=    RequestsLibrary.Get_Request    restconf    ${RESTCONF_GET_SUBSCRIPTION_URI}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Be_Equal_As_Strings    ${resp.status_code}    200    Response    status code error
    ${location}=    Collections.Get_From_Dictionary    ${resp.headers}    location
    BuiltIn.Log    ${location}
    BuiltIn.Set_Suite_Variable    ${location}

Start_Receiver
    [Documentation]    Start the websocket listener
    ${output}=    SSHLibrary.Write    python wsreceiver.py --uri ${location} --count 2 --logfile ${RECEIVER_LOG_FILE} ${RECEIVER_OPTIONS}
    BuiltIn.Log    ${output}
    ${output}=    SSHLibrary.Read    delay=2s
    BuiltIn.Log    ${output}

Change_Config
    [Documentation]    Make a change in configuration.
    [Tags]    critical
    ${body}=    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA}
    BuiltIn.Log    ${RESTCONF_CONFIG_URI}
    BuiltIn.Log    ${body}
    ${resp}=    RequestsLibrary.Post_Request    restconf    ${RESTCONF_CONFIG_URI}    headers=${SEND_ACCEPT_XML_HEADERS}    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Be_Equal_As_Strings    ${resp.status_code}    204
    BuiltIn.Log    ${CONFIG_NODES_API}
    ${resp}=    RequestsLibrary.Delete_Request    restconf    ${CONFIG_NODES_API}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Be_Equal_As_Strings    ${resp.status_code}    200

Check_Create_Notification
    [Documentation]    Check the websocket listener log for a change notification.
    [Tags]    critical
    ${notification}=    SSHLibrary.Execute_Command    cat ${RECEIVER_LOG_FILE}
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
    ${data}=    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA}
    BuiltIn.Log    ${data}
    BuiltIn.Log    ${notification}
    ${packed_data}=    String.Remove_String    ${data}    ${SPACE}
    ${packed_notification}=    String.Remove_String    ${notification}    ${SPACE}
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
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=receiver
    Utils.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/wsreceiver.py
    ${output_log}    ${error_log}=    SSHLibrary.Execute Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
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
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Log_Response
    [Arguments]    ${resp}
    [Documentation]    Log response.
    BuiltIn.Log    ${resp}
    BuiltIn.Log    ${resp.headers}
    BuiltIn.Log    ${resp.content}

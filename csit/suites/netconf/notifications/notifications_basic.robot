*** Settings ***
Documentation       Basic tests for BGP application peer.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 Test suite performs basic subscribtion case for data store notifications.
...                 For procedure description see the
...                 https://wiki.opendaylight.org/view/OpenDaylight_Controller:MD-SAL:Restconf:Change_event_notification_subscription
...
...
...                 This suite uses inventory (config part) as an area to make dummy writes into,
...                 just to trigger data change listener to produce a notification.
...                 Openflowplugin may have some data there, and before Boron, netconf-connector
...                 was also exposing some data in inventory.
...
...                 To avoid unexpected responses, this suite depetes all data from config inventory,
...                 so this suite should not be followed by any suite expecting default data there.
...
...                 Covered bugs:
...                 Bug 3934 - Websockets: Scope ONE doesn't work correctly
...
...                 TODO: Use cars/people model for data

Library             Collections
Library             OperatingSystem
Library             RequestsLibrary
Library             SSHLibrary    timeout=10s
Library             XML
Resource            ${CURDIR}/../../../libraries/CompareStream.robot
Resource            ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource            ${CURDIR}/../../../libraries/FailFast.robot
Resource            ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource            ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource            ${CURDIR}/../../../libraries/Restconf.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource            ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource            ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource            ${CURDIR}/../../../variables/Variables.robot

Suite Setup         Setup_Everything
Suite Teardown      Teardown_Everything
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown       SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed


*** Variables ***
${TEMPLATE_FOLDER}              ${CURDIR}/templates
${RFC8040_STREAMS_URI}          rests/data/ietf-restconf-monitoring:restconf-state/streams
${NODES_STREAM_PATH}            network-topology:network-topology/datastore=CONFIGURATION/scope=BASE
${RESTCONF_SUBSCRIBE_DATA}      subscribe.xml
${RESTCONF_CONFIG_DATA}         config_data.xml
${RECEIVER_LOG_FILE}            receiver.log
${CONTROLLER_LOG_LEVEL}         INFO


*** Test Cases ***
Create_DCN_Stream
    [Documentation]    Create DCN stream.
    [Tags]    critical
    Comment    Create DCN subscription
    ${body} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_SUBSCRIBE_DATA}
    ${uri} =    Restconf.Generate URI    sal-remote:create-data-change-event-subscription    rpc
    ${resp} =    RequestsLibrary.Post_On_Session
    ...    restconf
    ...    ${uri}
    ...    headers=${SEND_ACCEPT_XML_HEADERS}
    ...    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${stream_name} =    XML.Get_Element_Text    ${resp.content}    stream-name
    ${RFC8040_DCN_STREAM_URI} =    CompareStream.Set_Variable_If_At_Least_Calcium
    ...    ${RFC8040_STREAMS_URI}/stream=${stream_name}
    ...    ${RFC8040_STREAMS_URI}/stream/data-change-event-subscription/${NODES_STREAM_PATH}
    BuiltIn.Log    ${RFC8040_DCN_STREAM_URI}
    BuiltIn.Set_Suite_Variable    ${RFC8040_DCN_STREAM_URI}

Subscribe_To_DCN_Stream
    [Documentation]    Subscribe to DCN streams.
    [Tags]    critical
    ${resp} =    RequestsLibrary.Get_On_Session
    ...    restconf
    ...    url=${RFC8040_DCN_STREAM_URI}
    ...    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${xpath} =    CompareStream.Set_Variable_If_At_Least_Calcium
    ...    access[2]/location    .
    ${STREAM_LOCATION} =    XML.Get_Element_Text    ${resp.content}    ${xpath}
    BuiltIn.Log    ${STREAM_LOCATION}
    BuiltIn.Set_Suite_Variable    ${STREAM_LOCATION}

List_DCN_Streams
    [Documentation]    List DCN streams.
    [Tags]    critical
    ${resp} =    RequestsLibrary.Get_On_Session
    ...    restconf
    ...    url=${RFC8040_DCN_STREAM_URI}
    ...    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Comment    Stream only shows in RFC URL.
    BuiltIn.Should_Contain    ${resp.text}    ${STREAM_LOCATION}

Start_Receiver
    [Documentation]    Start the WSS/SSE listener
    ${output} =    SSHLibrary.Write    python3 ssereceiver.py --uri ${STREAM_LOCATION} --logfile ${RECEIVER_LOG_FILE}
    BuiltIn.Log    ${output}
    ${output} =    SSHLibrary.Read    delay=2s
    BuiltIn.Log    ${output}

Change_DS_Config
    [Documentation]    Make a change in DS configuration.
    [Tags]    critical
    ${body} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA}
    ${uri} =    BuiltIn.Set_Variable    /rests/data/network-topology:network-topology
    ${resp} =    RequestsLibrary.Put_On_Session
    ...    restconf
    ...    ${uri}
    ...    headers=${SEND_ACCEPT_XML_HEADERS}
    ...    data=${body}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${uri} =    BuiltIn.Set_Variable    /rests/data/network-topology:network-topology/topology=netconf-notif
    ${resp} =    RequestsLibrary.Delete_On_Session    restconf    ${uri}    headers=${SEND_ACCEPT_XML_HEADERS}
    Log_Response    ${resp}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Check_Notification
    [Documentation]    Check the WSS/SSE listener log for a change notification.
    [Tags]    critical
    ${notification} =    SSHLibrary.Execute_Command    cat ${RECEIVER_LOG_FILE}
    BuiltIn.Log    ${notification}
    BuiltIn.Set_Suite_Variable    ${notification}
    BuiltIn.Should_Contain    ${notification}    <notification xmlns=
    BuiltIn.Should_Contain    ${notification}    <eventTime>
    BuiltIn.Should_Contain    ${notification}    <data-changed-notification xmlns=
    ${operation} =    CompareStream.Set_Variable_If_At_Least_Calcium    created    updated
    BuiltIn.Should_Contain    ${notification}    <operation>${operation}</operation>
    BuiltIn.Should_Contain    ${notification}    </data-change-event>
    BuiltIn.Should_Contain    ${notification}    </data-changed-notification>
    BuiltIn.Should_Contain    ${notification}    </notification>

Check_Delete_Notification
    [Documentation]    Check the WSS/SSE listener log for a delete notification.
    [Tags]    critical
    BuiltIn.Should_Contain    ${notification}    <operation>deleted</operation>

Check_Bug_3934
    [Documentation]    Check the WSS/SSE listener log for the bug correction.
    [Tags]    critical
    ${data} =    OperatingSystem.Get_File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA}
    BuiltIn.Log    ${data}
    BuiltIn.Log    ${notification}
    ${packed_data} =    String.Remove_String    ${data}    \n
    ${packed_data} =    String.Remove_String    ${packed_data}    ${SPACE}
    ${packed_notification} =    String.Remove_String    ${notification}    \n
    ${packed_notification} =    String.Remove_String    ${packed_notification}    \\n
    ${packed_notification} =    String.Remove_String    ${packed_notification}    ${SPACE}
    BuiltIn.Should_Contain    ${packed_notification}    ${packed_data}
    [Teardown]    Report_Failure_Due_To_Bug    3934


*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    SSHKeywords.Open_Connection_To_Tools_System
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/wsreceiver.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/ssereceiver.py
    ${stdout}    ${stderr} =    SSHLibrary.Execute_Command
    ...    sudo apt-get install -y python3-pip
    ...    return_stdout=True
    ...    return_stderr=True
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    ${stdout}    ${stderr} =    SSHLibrary.Execute_Command
    ...    python3 -m pip install --user --upgrade pip setuptools wheel
    ...    return_stdout=True
    ...    return_stderr=True
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    ${stdout}    ${stderr} =    SSHLibrary.Execute_Command
    ...    python3 -m pip install --user websocket-client asyncio aiohttp aiohttp-sse-client coroutine
    ...    return_stdout=True
    ...    return_stderr=True
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    RequestsLibrary.Create_Session    restconf    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}

Teardown_Everything
    [Documentation]    Close connections.
    ...    Tear down imported Resources.
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Log_Response
    [Documentation]    Log response.
    [Arguments]    ${resp}
    BuiltIn.Log    ${resp}
    BuiltIn.Log    ${resp.headers}
    BuiltIn.Log    ${resp.text}

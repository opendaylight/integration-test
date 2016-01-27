*** Settings ***
Documentation     Basic tests for BGP application peer.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic subscribtion case for data store notifications
...
...               Bug 3934 - Websockets: Scope ONE doesn't work correctly
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
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
${RESTCONF_SUBSCRIBE_URI}     /restconf/operations/sal-remote:create-data-change-event-subscription
${RESTCONF_SUBSCRIBE_DATA}     subscribe.xml
${RESTCONF_GET_SUBSCRIPTION_URI}     restconf/streams/stream/opendaylight-inventory:nodes/datastore=CONFIGURATION/scope=BASE
${RESTCONF_CONFIG_URI}    restconf/config
${RESTCONF_CONFIG_DATA}    config_data.xml
${WS_NOTIFICAION_URI}    opendaylight-inventory:nodes/datastore=CONFIGURATION/scope=BASE
${RECEIVER_OPTIONS}    ${EMPTY}
${RECEIVER_LOG_FILE}    wsreceiver.log
${RECEIVER_COMMAND}    python wsreceiver.py --uri ws://${CONTROLLER}:8185/${NOTIFICAION_URI} --logfile ${RECEIVER_LOG_FILE} ${RECEIVER_OPTIONS}
${CONTROLLER_LOG_LEVEL}    INFO

*** Test Cases ***
Create_Subscribtion
    [Documentation]    Subscribe for notifications.
    [Tags]    critical
    ${body}=    OperatingSystem.Get File    ${TEMPLATE_FOLDER}/${RESTCONF_SUBSCRIBE_DATA}
    Log    ${body}
    ${resp}=    RequestsLibrary.Put Request    restconf    ${RESTCONF_SUBSCRIBE_URI}    headers=${ACCEPT_XML}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Check_Subscribtion
    [Documentation]    Subscribe for notifications.
    [Tags]    critical
    ${resp}=    RequestsLibrary.Get Request    restconf    ${RESTCONF_GET_SUBSCRIPTION_URI}}    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Log    ${resp.headers}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.header}    ${WS_NOTIFICAION_URI}

Start_Receiver
    [Documentation]    Start the websocket listenerl
    ${output}=    SSHLibrary.Write    ${RECEIVER_COMMAND} ${RECEIVER_OPTIONS}
    BuiltIn.Log    ${output}

Change_Config
    [Documentation]    Make a change in configuration.
    [Tags]    critical
    ${body}=    OperatingSystem.Get File    ${TEMPLATE_FOLDER}/${RESTCONF_CONFIG_DATA}
    Log    ${body}
    ${resp}=    RequestsLibrary.Put Request    restconf    ${RESTCONF_CONFIG_DATA}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Check_Notification
    [Documentation]    Check the websocket listener log.
    [Tags]    critical
    ${output_log}=    SSHLibrary.Execute_Command    cat ${RECEIVER_LOG_FILE}
    Log    ${output_log}
    Should Contain    ${output_log}   <data-changed-notification xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:remote">
    Should Contain    ${output_log}   <path xmlns:rxgh="urn:opendaylight:inventory">/rxgh:nodes</path>
    Should Contain    ${output_log}   <operation>created</operation>

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=receiver
    Utils.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/wstools/wsreceiver.py
    RequestsLibrary.Create Session    restconf    http://${CONTROLLER}:${RESTCONFPORT}/    auth=${AUTH}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections


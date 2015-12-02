*** Settings ***
Documentation     netconf-restperfclient Update performance test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform given count of update operations on device data mounted onto a
...               netconf connector (using the netconf-testtool-restperfclient tool) and
...               see how much time it took. More exactly, it sends the data to a restconf
...               mountpoint of the netconf connector belonging to the device, which turns
...               out to turn the first request sent to a "create" request and the
...               remaining requests to "update" requests (due to how the testtool device
...               behavior is implemented).
...
...               TODO: The "Wait_Until_Prompt" keyword shall probably be turned into a
...               reusable piece and moved into SSHKeywords. There is a bunch of other
...               test suites (e.g. PCEP, BGP) which contain the same or similar pieces of
...               code.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DIRECTORY_WITH_CRUD_TEMPLATES}    ${CURDIR}/../../../variables/netconf/CRUD
${DIRECTORY_WITH_TEMPLATE_FOLDERS}    ${CURDIR}/../../../variables/netconf/RestPerfClient
${DEVICE_NAME}    ${FIRST_TESTTOOL_PORT}-sim-device
${REQUEST_COUNT}    65536

*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    # Start test tool
    SSHLibrary.Switch_Connection    ${testtool}
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas    mdsal=false

Configure_Device_On_Netconf
    [Documentation]    Configure the testtool device on Netconf connector.
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME}

Wait_For_Device_To_Become_Connected
    [Documentation]    Wait until the device becomes available through Netconf.
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}

Create_Device_Data
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    NetconfViaRestconf.Post_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_CRUD_TEMPLATES}${/}cars    ${template_as_string}

Deploy_And_Run_RestPerfClient
    [Documentation]    Deploy and execute restperfclient, asking it to send the specified amount of requests to the netconf connector of the device.
    SSHLibrary.Switch_Connection    ${restperfclient}
    SSHLibrary.Put_File    ${CURDIR}/../../../variables/netconf/RestPerfClient/request1.json
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf/netconf-testtool    rest-perf-client
    ${timeout}=    BuiltIn.Evaluate    ${REQUEST_COUNT}*2
    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    ${options}=    BuiltIn.Set_Variable    --ip ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --edits ${REQUEST_COUNT}
    ${options}=    BuiltIn.Set_Variable    ${options} --destination /restconf/config/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount/car:cars
    ${options}=    BuiltIn.Set_Variable    ${options} --edit-content request1.json
    ${command}    BuiltIn.Set_Variable    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} ${options}
    BuiltIn.Log    Running restperfclient: ${command}
    Execute_Command_Passes    ${command} >restperfclient.log 2>&1
    SSHLibrary.Get_File    restperfclient.log
    ${result}=    SSHLibrary.Execute_Command    grep "FINISHED. Execution time:" restperfclient.log
    BuiltIn.Should_Not_Be_Equal    '${result}'    ''

Deconfigure_Device_From_Netconf
    [Documentation]    Deconfigure the testtool device on Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords
    # Connect to the tools system (rest-perf-client)
    ${restperfclient}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${restperfclient}    ${restperfclient}
    # Initialize artifact deployment infrastructure.
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    ${testtool}=    SSHLibrary.Get Connection
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool.index}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Switch_Connection    ${testtool}
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool

Wait_Until_Prompt
    [Documentation]    Wait until prompt appears or timeout occurs. When timeout occurs, send Ctrl-C and then wait for the prompt again.
    ...    This is necessary because the restperfclient can crash and hang, requiring that Ctrl-C character to get rid of it for good.
    ${status}    ${result}=    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    Return_From_Keyword_If    '${status}' == 'PASS'
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Read_Until_Prompt

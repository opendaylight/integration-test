*** Settings ***
Documentation     netconf-restperfclient update performance test suite (clustered setup).
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
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
...               The difference from the "single node" test suite (see
...               ../scale/performance.robot) is that the device is configured and the data
...               on it created using one node in the cluster and the update operations are
...               issued on a different node. This forces the cluster nodes to communicate
...               with each other about the data to be sent to the device.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/RestPerfClient.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_NAME}    ${FIRST_TESTTOOL_PORT}-sim-device
${REQUEST_COUNT}    65536
${directory_with_crud_templates}    ${CURDIR}/../../../variables/netconf/CRUD
${DEVICE_DATA_CONNECT_TIMEOUT}    60s

*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    # Start test tool
    SSHLibrary.Switch_Connection    ${testtool}
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    debug=false    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas    mdsal=false

Configure_Device_On_Netconf
    [Documentation]    Configure the testtool device on Netconf connector, using node 1.
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME}    device_type=configure-via-topology    session=node1

Wait_For_Device_To_Become_Connected
    [Documentation]    Wait until the device becomes available through Netconf on node 1.
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node1

Wait_For_Device_Data_To_Be_Seen
    [Documentation]    Wait until the device data show up at node 2.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_DATA_CONNECT_TIMEOUT}    1s    Check_Data_Present

Create_Device_Data
    [Documentation]    Send some sample test data into the device through node 2 and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_crud_templates}${/}cars    ${template_as_string}    session=node2

Run_Restperfclient
    [Documentation]    Deploy and execute restperfclient, asking it to send the specified amount of requests to the netconf connector of the device through node 3.
    ...    The duration of this test case is the main performance metric.
    ${url}=    BuiltIn.Set_Variable    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount/car:cars
    RestPerfClient.Invoke_Restperfclient    ${TESTTOOL_DEVICE_TIMEOUT}    ${url}    ip=${ODL_SYSTEM_3_IP}

Check_For_Failed_Requests
    [Documentation]    Make sure there are no failed requests in the restperfclient log.
    ...    This is a separate test case to distinguish between restperfclient
    ...    failure and failed requests. Failed requests are rejected because
    ...    we don't want to test performance of ODL rejecting our requests.
    ...    If this test case fails, then the duration of Run_Restperfclient
    ...    cannot be trusted to show the real performance of the cluster.
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    thread timed out
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Request failed
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Status code
    BuiltIn.Should_Be_Equal    '${result}'    ''

Cleanup_And_Collect
    [Documentation]    Deconfigure the testtool device on Netconf connector using node 1.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    RestPerfClient.Collect_From_Restperfclient
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}    session=node1

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Calculate and set the value of the timeout
    ${value}=    BuiltIn.Evaluate    ${REQUEST_COUNT}/50+10
    Utils.Set_User_Configurable_Variable_Default    TESTTOOL_DEVICE_TIMEOUT    ${value} s
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    RestPerfClient.Setup_Restperfclient
    # Connect to the tools system (testtool)
    ${testtool}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool}
    # Create sessions
    RequestsLibrary.Create_Session    node1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}

Check_Data_Present
    ${url}=    Builtin.Set_Variable    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount
    ${data}=    TemplatedRequests.Get_As_Xml_From_Uri    ${url}    session=node2
    BuiltIn.Should_Be_Equal_As_Strings    ${data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    RestPerfClient.Teardown_Restperfclient
    SSHLibrary.Switch_Connection    ${testtool}
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool

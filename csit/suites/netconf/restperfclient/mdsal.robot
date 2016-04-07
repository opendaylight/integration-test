*** Settings ***
Documentation     netconf-restperfclient MDSAL performance test suite.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform given count of update operations on ODL MDSAL. In first half the
...               requests are directed directly to MDSAL via Restconf and in the second
...               half the MDSAL is mounted onto a netconf connector and the reqursts are
...               directed to that connector. In both cases the netconf-testtool-restperfclient
...               tool is used to generate and send the requests and the requests are sent
...               synchronously as the netconf connector mounted MDSAL does not support
...               asynchronous requests. The restperfclient is used to generate the "update"
...               requests, the "create" request is issued in a sepate test case.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           RequestsLibrary
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/RestPerfClient.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DIRECTORY_WITH_TEMPLATE_FOLDERS}    ${CURDIR}/../../../variables/netconf/RestPerfClient
${REQUEST_COUNT}    65536

*** Test Cases ***
Create_Test_Data_For_Direct_Access
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    TemplatedRequests.Post_As_Xml_Templated    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}cars    {}

Run_RestPerfClient_Directly_On_MDSAL
    [Documentation]    Deploy and execute restperfclient, asking it to send the specified amount of requests to the MDSAL via Restconf.
    ${url}=    BuiltIn.Set_Variable    /restconf/config/car:cars
    RestPerfClient.Invoke_Restperfclient    ${DIRECT_MDSAL_TIMEOUT}    ${url}    testcase=direct

Check_For_Failed_Direct_MDSAL_Requests
    [Documentation]    Make sure there are no failed requests in the restperfclient log.
    ...    This is a separate test case to distinguish between restperfclient
    ...    failure and failed requests. Failed requests are rejected because
    ...    we don't want to test performance of ODL rejecting our requests.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    thread timed out
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Request failed
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Status code
    BuiltIn.Should_Be_Equal    '${result}'    ''

Cleanup_And_Collect_For_Direct_Access
    [Documentation]    Cleanup the test data produced by the direct MDSAL access.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    RestPerfClient.Collect_From_Restperfclient
    TemplatedRequests.Delete_Templated    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}cars-delete    {}

Create_Test_Data_For_Connector_Access
    [Documentation]    Create the test data container again so it is ready for the netconf connector test.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Post_As_Xml_Templated    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}cars    {}

Configure_ODL_As_A_Device_On_Netconf
    [Documentation]    Configure ODL MDSAL Northbound as a Netconf device on a Netconf connector.
    NetconfKeywords.Configure_Device_In_Netconf    odl-mdsal-northbound-via-netconf-connector    device_address=${ODL_SYSTEM_IP}    device_port=${ODL_NETCONF_MDSAL_PORT}    device_user=${ODL_NETCONF_USER}    device_password=${ODL_NETCONF_PASSWORD}
    NetconfKeywords.Wait_Device_Connected    odl-mdsal-northbound-via-netconf-connector

Run_RestPerfClient_Through_Netconf_Connector
    [Documentation]    Ask RestPerfClient to send the requests to the MDSAL mapped via a netconf connector.
    ${url}=    BuiltIn.Set_Variable    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/odl-mdsal-northbound-via-netconf-connector/yang-ext:mount/car:cars
    RestPerfClient.Invoke_Restperfclient    ${NETCONF_CONNECTOR_MDSAL_TIMEOUT}    ${url}    testcase=netconf-connector

Check_For_Failed_Netconf_Connector_Requests
    [Documentation]    Make sure there are no failed requests in the restperfclient log.
    ...    This is a separate test case to distinguish between restperfclient
    ...    failure and failed requests. Failed requests are rejected because
    ...    we don't want to test performance of ODL rejecting our requests.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Set_Known_Bug_Id    5581
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    thread timed out
    BuiltIn.Should_Be_Equal    '${result}'    ''
    Set_Unknown_Bug_Id
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Request failed
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Status code
    BuiltIn.Should_Be_Equal    '${result}'    ''

Deconfigure_ODL_From_Netconf
    [Documentation]    Deconfigure the ODL MDSAL Northbound attached to a Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    odl-mdsal-northbound-via-netconf-connector

Cleanup_And_Collect_For_Connector_Access
    [Documentation]    Delete the test data produced by the Netconf connector MDSAL access.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    RestPerfClient.Collect_From_Restperfclient
    TemplatedRequests.Delete_Templated    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}cars-delete    {}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    RestPerfClient.Setup_Restperfclient
    # Calculate timeouts
    ${value}=    BuiltIn.Evaluate    ${REQUEST_COUNT}/50+10
    Utils.Set_User_Configurable_Variable_Default    DIRECT_MDSAL_TIMEOUT    ${value} s
    ${value}=    BuiltIn.Evaluate    ${REQUEST_COUNT}/10+10
    Utils.Set_User_Configurable_Variable_Default    NETCONF_CONNECTOR_MDSAL_TIMEOUT    ${value} s

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    RestPerfClient.Teardown_Restperfclient

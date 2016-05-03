*** Settings ***
Documentation     netconf-connector readiness test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Try to detect whether Netconf is up and running and wait for
...               it for a configurable time if it is not yet up and running.
...
...               By default this is done by querying netconf-connector and
...               seeing whether it works. Some testsuites expect netconf-connector
...               to be ready as soon as possible and will fail if it is not. We
...               want to see a failure if this is the cause of the failure.
...
...               If the netconf-connector is not ready upon startup (as seen by
...               the first test case failing), the second case starts to repeat
...               the query for a minute to see whether it is going "to fix itself"
...               within the minute. If yes, then the testcase will pass, which
...               indicates that the "ODL cooldown" of 1 minute is not long enough
...               to allow for netconf-connector to initialize properly.
...
...               If the USE_NETCONF_CONNECTOR is forced to be False by the Robot
...               invocation argument, then the suite does not use netconf
...               connector for the readiness detection but merely waits for the
...               Netconf topology to appear. This is a weaker condition when
...               Netconf connector is about to be used but is necessary if the
...               suite in question does not use the Netconf connector.
...
...               If the first test case passed, then the second test case does
...               nothing.
...
...               The third test case then checks whether Netconf can pretty print
...               data. This sometimes makes problems, most likely due to too
...               new Robot Requests library with an interface incompatible with
...               this test suite.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           RequestsLibrary
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${netconf_is_ready}    False
${NETCONFREADY_WAIT}    60s
${USE_NETCONF_CONNECTOR}    True
${DEBUG_LOGGING_FOR_EVERYTHING}    False
${NETCONFREADY_WAIT_MDSAL}    60s

*** Test Cases ***
Check_Whether_Netconf_Is_Up_And_Running
    [Documentation]    Make one request to Netconf topology to see whether Netconf is up and running.
    [Tags]    exclude
    SetupUtils.Set_Known_Bug_Id    4708
    Check_Netconf_Up_And_Running
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True

Wait_For_Netconf
    [Documentation]    Wait for the Netconf to go up for configurable time.
    [Tags]    critical
    BuiltIn.Set_Suite_Variable    ${netconf_not_ready_cause}    4583
    SetupUtils.Set_Known_Bug_Id    4583
    BuiltIn.Run_Keyword_Unless    ${netconf_is_ready}    BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_WAIT}    1s    Check_Netconf_Up_And_Running
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True

Check_For_Bug_5014
    [Documentation]    If Netconf appears to be down, it may be due to bug 5014. Check if it is so and fail if yes.
    ...    Bug 5014 is about Netconf playing dead on boot until a device
    ...    configuration request is sent to it. To uncover this attempt to
    ...    configure and then deconfigure a device and then check if Netconf
    ...    is now up and running. If that turns out to be true, fail the case
    ...    as this signifies the bug 5014 to be present. Skip this testcase
    ...    if Netconf is detected to be up and running.
    [Tags]    critical
    SetupUtils.Set_Known_Bug_Id    5014
    BuiltIn.Pass_Execution_If    ${netconf_is_ready}    Netconf was detected to be up and running so bug 5014 did not show up.
    ${status}    ${error}=    BuiltIn.Run_Keyword_And_Ignore_Error    Check_Netconf_Usable
    BuiltIn.Run_Keyword_If    '${status}'=='PASS'    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True
    BuiltIn.Should_Be_Equal    '${status}'    'FAIL'

Check_Whether_Netconf_Can_Pretty_Print
    [Documentation]    Make one request to netconf-connector and see if it works.
    [Tags]    critical
    SetupUtils.Set_Known_Bug_Id    ${netconf_not_ready_cause}
    BuiltIn.Run_Keyword_Unless    ${netconf_is_ready}    Fail    Netconf is not ready so it can't pretty-print now.
    Check_Netconf_Up_And_Running    ?prettyPrint=true

Wait_For_MDSAL
    [Documentation]    Wait for the MDSAL feature to become online
    SetupUtils.Set_Known_Bug_Id    4583
    ${status}    ${message}=    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Verify_Feature_Is_Installed    odl-netconf-mdsal
    BuiltIn.Run_Keyword_If    '${status}' == 'FAIL'    BuiltIn.Pass_Execution    The 'odl-netconf-mdsal' feature is not installed so no need to wait for it.
    SSHKeywords.Open_Connection_To_ODL_System
    BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_WAIT_MDSAL}    1s    Check_Netconf_MDSAL_Up_And_Running
    SSHLibrary.Close_Connection

*** Keywords ***
Setup_Everything
    [Documentation]    Setup requests library and log into karaf.log that the netconf readiness wait starts.
    ${connector}=    BuiltIn.Set_Variable_If    ${USE_NETCONF_CONNECTOR}    /node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/controller-config    ${EMPTY}
    BuiltIn.Set_Suite_Variable    ${netconf_connector}    ${connector}
    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    KarafKeywords.Log_Message_To_Controller_Karaf    Starting Netconf readiness test suite
    BuiltIn.Run_Keyword_If    ${DEBUG_LOGGING_FOR_EVERYTHING}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG
    RequestsLibrary.Create_Session    ses    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords

Teardown_Everything
    [Documentation]    Destroy all sessions in the requests library and log into karaf.log that the netconf readiness wait is over.
    KarafKeywords.Log_Message_To_Controller_Karaf    Ending Netconf readiness test suite
    RequestsLibrary.Delete_All_Sessions

Check_Netconf_Up_And_Running
    [Arguments]    ${pretty_print}=${EMPTY}
    [Documentation]    Make a request to netconf connector's list of mounted devices and check that the request was successful.
    ${response}=    RequestsLibrary.Get_Request    ses    restconf/config/network-topology:network-topology/topology/topology-netconf${netconf_connector}${pretty_print}
    BuiltIn.Log    ${response.text}
    ${status}=    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Should_Contain    ${response.text}    data model content does not exist
    BuiltIn.Run_Keyword_If    ${status}    BuiltIn.Set_Suite_Variable    ${netconf_not_ready_cause}    5832
    BuiltIn.Run_Keyword_If    ${status}    SetupUtils.Set_Known_Bug_Id    5832
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200

Check_Netconf_Usable
    NetconfKeywords.Configure_Device_In_Netconf    test-device    device_type=configure-via-topology
    NetconfKeywords.Remove_Device_From_Netconf    test-device
    Check_Netconf_Up_And_Running

Check_Netconf_MDSAL_Up_And_Running
    ${count}=    SSHKeywords.Count_Port_Occurences    ${ODL_NETCONF_MDSAL_PORT}    LISTEN    java
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    1

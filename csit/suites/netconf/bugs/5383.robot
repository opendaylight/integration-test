*** Settings ***
Documentation     netconf-connector bug 5383 regression test suite.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This is a test suite aimed to catch bug 5383. It first installs
...               netconf connector and then it installs BGPCEP features. If bug
...               5383 is present, the netconf connector will be dead (it will get
...               killed by the new schemas deployed by BGPCEP) so the installation
...               is followed by a modified copy of the Netconf Readiness suite that
...               reports the bug 5383 as the cause of any failures.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
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

*** Test Cases ***
Wait_For_Netconf_Before_Bgpcep_Installed
    [Documentation]    Wait for the Netconf to go up for configurable time.
    [Tags]    critical
    [Timeout]    ${NETCONFREADY_WAIT}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_WAIT}    1s    Check_Netconf_Up_And_Running
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Check_For_Bug_5014
    [Documentation]    If Netconf appears to be down, it may be due to bug 5014. Check if it is so and fail if yes.
    ...    Bug 5014 is about Netconf playing dead on boot until a device
    ...    configuration request is sent to it. To uncover this attempt to
    ...    configure and then deconfigure a device and then check if Netconf
    ...    is now up and running. If that turns out to be true, fail the case
    ...    as this signifies the bug 5014 to be present. Skip this testcase
    ...    if Netconf is detected to be up and running.
    [Tags]    critical
    [Timeout]    2s
    BuiltIn.Pass_Execution_If    ${netconf_is_ready}    Netconf was detected to be up and running so bug 5014 did not show up.
    ${status}    ${error}=    BuiltIn.Run_Keyword_And_Ignore_Error    Check_Netconf_Usable
    BuiltIn.Run_Keyword_If    '${status}'=='PASS'    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True
    BuiltIn.Should_Be_Equal    '${status}'    'FAIL'
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5014

Check_Whether_Netconf_Is_Alive_Before_Bgpcep_Installed
    [Documentation]    Make sure the netconf connector is alive and well. If not, this failure will tell us that
    [Timeout]    2s
    BuiltIn.Should_Be_True    ${netconf_is_ready}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Check_Whether_Netconf_Can_Pretty_Print_Before_Bgpcep_Installed
    [Documentation]    Make one pretty-print request to netconf-connector and see if it works.
    [Tags]    critical
    [Timeout]    2s
    BuiltIn.Run_Keyword_Unless    ${netconf_is_ready}    Fail    Netconf is not ready so it can't pretty-print now.
    Check_Netconf_Up_And_Running    ?prettyPrint=true
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5383

Install_Bgpcep
    [Documentation]    Install BGPCEP which deploys additional YANG files and thus disrupts netconf connector.
    [Tags]    critical
    [Timeout]    5m
    BuiltIn.Run_Keyword_Unless    ${netconf_is_ready}    BuiltIn.Fail    Netconf did not install properly so it is not possible to test for bug 5383.
    Install_a_Feature    odl-bgpcep-pcep-all
    Install_a_Feature    odl-bgpcep-bgp-all
    Install_a_Feature    odl-bgpcep-bgp
    Install_a_Feature    odl-bgpcep-pcep

Check_Whether_Netconf_Is_Alive_After_Bgpcep_Installed
    [Documentation]    If Netconf is dead now, we caught bug 5383.
    [Tags]    critical
    [Timeout]    ${NETCONFREADY_WAIT}
    BuiltIn.Run_Keyword_Unless    ${netconf_is_ready}    BuiltIn.Fail    Netconf did not install properly so it is not possible to test for bug 5383.
    Set_Known_Bug_Id    5383
    BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_WAIT}    1s    Check_Netconf_Up_And_Running
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Check_Whether_Netconf_Can_Pretty_Print_After_Bgpcep_Installed
    [Documentation]    If pretty-print requests stop working, weagain got the bug 5383 caught.
    [Tags]    critical
    [Timeout]    2s
    BuiltIn.Run_Keyword_Unless    ${netconf_is_ready}    BuiltIn.Fail    Netconf did not install properly so it is not possible to test for bug 5383.
    Set_Known_Bug_Id    5383
    Check_Netconf_Up_And_Running    ?prettyPrint=true
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

*** Keywords ***
Setup_Everything
    [Documentation]    Setup requests library and log into karaf.log that the netconf readiness wait starts.
    ${connector}=    BuiltIn.Set_Variable_If    ${USE_NETCONF_CONNECTOR}    /node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/controller-config    ${EMPTY}
    BuiltIn.Set_Suite_Variable    ${netconf_connector}    ${connector}
    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    KarafKeywords.Log_Message_To_Controller_Karaf    Starting Bug 5383 detection test suite
    BuiltIn.Run_Keyword_If    ${DEBUG_LOGGING_FOR_EVERYTHING}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG
    RequestsLibrary.Create_Session    ses    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}
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
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200

Check_Netconf_Usable
    NetconfKeywords.Configure_Device_In_Netconf    test-device    device_type=configure-via-topology
    NetconfKeywords.Remove_Device_From_Netconf    test-device
    Check_Netconf_Up_And_Running

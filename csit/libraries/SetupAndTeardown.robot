*** Settings ***
Documentation     Resource implementing "new style setup and teardown"
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This implements new style setup and teardown which allows easier
...               implementation of "on demand resource setup", more automation for
...               test teardown and encapsulation of the setup/teardown details.
...
...               The Robot Framework has very primitive support for test case setup
...               and teardown which requires the people to manage these activities
...               by hand. This is usually sufficient when running very simple tests
...               which involve using only BuiltIn or similar simple modules but
...               loses breath quickly when the tests run into a need to perform
...               multiple setup and/or teardown actions on one or more tests. This
...               problem is magnified when these setup and/or teardown actions are
...               initialization keywords needed by one or more resources.
...
...               The improved support allows the tests and their resources to register
...               setup and teardown actions "on the fly" and allows for having multiple
...               setup and teardown actions without the need to package them into a
...               dedicated keyword to overcome the limitations of the
Library           Collections
Resource          ${CURDIR}/FastFailing.robot
Resource          ${CURDIR}/KarafKeywords.robot

*** Keywords ***
SetupAndTeardown__Run_Keywords_From_Dictionary
    [Arguments]    ${dictionary}
    ${list}=    Collections.Get_Dictionary_Values    ${dictionary}
    : FOR    ${keyword}    IN    @{list}
    \    BuiltIn.Run_Keyword    @{keyword}

SetupAndTeardown__Reset_Temporary_Setups_And_Teardowns
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${SetupAndTeardown__test_setups}    ${tmp}
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${SetupAndTeardown__test_teardowns}    ${tmp}

Generic_Suite_Setup
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${SetupAndTeardown__permanent_test_setups}    ${tmp}
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${SetupAndTeardown__permanent_test_teardowns}    ${tmp}
    SetupAndTeardown__Reset_Temporary_Setups_And_Teardowns
    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    KarafKeywords.Log_Test_Suite_Start_To_Controller_Karaf
    Setup_Everything

Generic_Suite_Teardown
    Teardown_Everything

Generic_Test_Setup
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
    SetupAndTeardown__Run_Keywords_From_Dictionary    ${SetupAndTeardown__permanent_test_setups}

Generic_Test_Teardown
    SetupAndTeardown__Run_Keywords_From_Dictionary    ${SetupAndTeardown__permanent_test_teardowns}

Register_Permanent_Test_Setup
    [Arguments]    ${name}    @{keyword}
    [Documentation]    Register a permanent test setup under the given name. The test setup remains in effect until unregistered.
    Collections.Set_To_Dictionary    ${SetupAndTeardown__permanent_test_setups}    ${name}    ${keyword}

Unregister_Permanent_Test_Setup
    [Arguments]    ${name}    @{keyword}
    [Documentation]    Unregister a permanent test teardown previously registered under the given name.
    Collections.Dictionary_Should_Contain_Key    ${SetupAndTeardown__permanent_test_teardowns}    ${name}    No permanent test setup with name '${name}' found.
    Collections.Remove_From_Dictionary    ${SetupAndTeardown__permanent_test_setups}    ${name}

Register_Permanent_Test_Teardown
    [Arguments]    ${name}    @{keyword}
    [Documentation]    Register a permanent test teardown under the given name. The test teardown remains in effect until unregistered.
    Collections.Set_To_Dictionary    ${SetupAndTeardown__permanent_test_teardowns}    ${name}    ${keyword}

Unregister_Permanent_Test_Teardown
    [Arguments]    ${name}    @{keyword}
    [Documentation]    Unregister a permanent test teardown previously registered under the given name.
    Collections.Dictionary_Should_Contain_Key    ${SetupAndTeardown__permanent_test_teardowns}    ${name}    No permanent test teardown with name '${name}' found.
    Collections.Pop_From_Dictionary    ${SetupAndTeardown__permanent_test_teardowns}    ${name}

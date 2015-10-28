*** Settings ***
Documentation     Fail fast behavior implementation for new style setup/teardown Robot suites.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Usage:
...
...               Simply set "FastFailing.Enable" as the setup of the
...               "fundamental test case" (the testcase whose failure
...               signifies that a bunch of following tests will also fail
...               because of some setup work not being done as it should be)
...               and set "FastFailing.Disable" as the teardown of the last
...               test case that depends on the setup work done by the
...               "fundamental test case".
...
...               If any failures occur after a "FastFailing.Enable", all
...               tests are quickly marked as failed without executing their
...               potentially time consuming steps. The fast failure marking
...               then stops at the first occurence of a test case with
...               "FastFailing.Disable".
Resource          SetupAndTeardown.robot

*** Variables ***
${FastFailing__SuiteFastFail}    False

*** Keywords ***
FastFailing__Check_Previous_Suite_Status
    BuiltIn.Run_Keyword_If    '''${FastFailing__SuiteFastFail}'''=='True'    BuiltIn.Fail    SKIPPED due to a failure in a previous fundamental test case.

FastFailing__Start_Failing_Fast_On_Failure
    BuiltIn.Run_Keyword_If_Test_Failed    BuiltIn.Set_Suite_Variable    ${FastFailing__SuiteFastFail}    True

FastFailing__Stop_Failing_Fast
    BuiltIn.Set_Suite_Variable    ${FastFailing__SuiteFastFail}    False

Enable
    SetupAndTeardown.Generic_Test_Setup
    FastFailing__Check_Previous_Suite_Status
    SetupAndTeardown.Register_Permanent_Test_Setup    FastFailing    FastFailing__Check_Previous_Suite_Status
    SetupAndTeardown.Register_Permanent_Test_Teardown    FastFailing    FastFailing__Start_Failing_Fast_On_Failure

Disable
    FastFailing__Stop_Failing_Fast
    SetupAndTeardown.Unregister_Permanent_Test_Setup    FastFailing
    SetupAndTeardown.Unregister_Permanent_Test_Teardown    FastFailing
    SetupAndTeardown.Generic_Test_Teardown

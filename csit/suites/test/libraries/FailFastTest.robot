*** Settings ***
Documentation     Unit test suite to FailFast library.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               TODO: Include more negative tests for WFGASSVCS and WFGEOSSVCS.
...               TODO: Current time values may be too brittle.
Suite Setup       Setup_Everything
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     FailFast_resetfakefail_Start_Failing_Fast_If_This_Failed
Resource          ${CURDIR}/../../../libraries/SysTest.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot

*** Test Cases ***
First_Case_Is_First_Fundamental_And_Passed
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    First case is first fundamental and did its setup correctly

Second_Case_Passed
    BuiltIn.Log    Second case has first dependency and passed

Third_Case_Passed
    BuiltIn.Log    Third case has first dependency and passed

Fourth_Case_Failed
    SysTest.Simulate_Failure    Fourth case has first dependency and failed

Fifth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Fifth case has first dependency and thus was skipped

Sixth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Sixth case has first dependency and thus was skipped too

Seventh_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Seventh case has no dependency so it is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Eighth_Case_Also_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Eighth case also has no dependency so it is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Ninth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Ninth case has first dependency again and thus was skipped

Tenth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    The tenth case has first dependency and thus was skipped too

Eleventh_Case_Drops_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    FailFast.Do_Not_Fail_Fast_From_Now_On
    BuiltIn.Log    Eleventh case drops the first dependency so it is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Twelveth_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Twelveth case has no dependency and thus is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Thirteenth_Case_Has_No_Dependency_And_Fails
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SysTest.Simulate_Failure    Thirteenth case has no dependency and thus is executed but failed
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Fourteenth_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Fourteenth case has no dependency and thus is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Fifteenth_Case_Is_Second_Fundamental_Case_And_Passes
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Fifteenth case is second fundamental and did its setup correctly

Sixteenth_Case_Passes
    BuiltIn.Log    Sixteenth case has second dependency and passed

Seventeenth_Case_Passes
    BuiltIn.Log    Seventeenth case has second dependency and also passed

Eighteenth_Case_Fails
    SysTest.Simulate_Failure    Eighteenth case has second dependency and failed

Nineteenth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Nineteenth case has second dependency and thus was skipped

Twelveth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Twelveth case also has second dependency and thus was skipped

Twelvefirst_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Twelvefirst case has no dependency and thus is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Twelvesecond_Case_Has_No_Dependency_And_Fails
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SysTest.Simulate_Failure    Twelvesecond case has no dependency and thus is executed but failed
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Twelvethird_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Twelvethird case has no dependency and thus is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Twelvefourth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Twelvefourth case has second dependency again and thus was skipped

Twelvefifth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Twelvefifth case also has second dependency and thus was skipped

Twelvesixth_Case_Drops_Second_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    FailFast.Do_Not_Fail_Fast_From_Now_On
    BuiltIn.Log    Twelvesixth case drops the second dependency so it is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Twelveseventh_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Twelveseventh case has no dependency and thus is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Twelveeighth_Case_Has_No_Dependency_And_Fails
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SysTest.Simulate_Failure    Twelveeighth case has no dependency and thus is executed but failed
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Twelveninth_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Twelveninth case has no dependency and thus is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Thirtieth_Case_Is_Third_Fundamental_Case_And_Passes
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Thirtieth case is third fundamental and did its setup correctly

Thirtyfirst_Case_Passed
    BuiltIn.Log    Thirtyfirst case has third dependency and passed

Thirtysecond_Case_Passed
    BuiltIn.Log    Thirtysecond case has third dependency and passed

Thirtythird_Case_Passed
    SysTest.Simulate_Failure    Thirtythird case has third dependency and failed

Thirtyfourth_Case_Drops_Third_Dependency_And_Fails
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    FailFast.Do_Not_Fail_Fast_From_Now_On
    SysTest.Simulate_Failure    Thirtyfourth case drops third dependency so it is executed but failed
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Thirtyfifth_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SysTest.Simulate_Failure    Thirtyfifth case has no dependency and thus is executed but fails
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Thirtysixth_Case_Is_Fourth_Fundamental_And_Failed
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SysTest.Simulate_Failure    Thirtysixth case is fourth fundamental and failed in its setup

Thirtyseventh_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Thirtyseventh case has fourth dependency and thus was skipped

Thirtyeighth_Case_Is_Skipped
    [Setup]    Check_Fail_Fast_Is_Failing
    BuiltIn.Log    Thirtyeighth case has fourth dependency and thus was skipped too

Thirtyninth_Case_Drops_Third_Dependency_And_Fails
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    FailFast.Do_Not_Fail_Fast_From_Now_On
    SysTest.Simulate_Failure    Thirtyninth case drops fourth dependency so it is executed but failed
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

Fortieth_Case_Has_No_Dependency
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Log    Fortieth case has no dependency and thus is executed and passes
    [Teardown]    FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed

*** Keywords ***
Setup_Everything
    SysTest.Initialize
    FailFast.Do_Not_Fail_Fast_From_Now_On

FailFast_resetfakefail_Start_Failing_Fast_If_This_Failed
    FailFast.Start_Failing_Fast_If_This_Failed
    SysTest.Reset_Failure_Simulation

FailFast_resetfakefail_Do_Not_Start_Failing_If_This_Failed
    FailFast.Do_Not_Start_Failing_If_This_Failed
    SysTest.Reset_Failure_Simulation

Check_Fail_Fast_Is_Failing
    BuiltIn.Run_Keyword_And_Expect_Error    SKIPPED due to a failure in a previous fundamental test case.    FailFast.Fail_This_Fast_On_Previous_Error

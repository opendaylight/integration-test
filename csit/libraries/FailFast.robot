*** Settings ***
Documentation     Robot keyword library (Resource) for implementing fail fast behavior in Robot suites.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This Resource uses suite variable SuiteFastFail, beware of possible conflicts.
...
...               Recommended usage:
...               In suite setup, call Do_Not_Fail_Fast_From_Now_On
...               Set Fail_This_Fast_On_Previous_Error as Test Setup
...               and Start_Failing_Fast_If_This_Failed as Test Teardown
...               in the suite setting table.
...               If you do not want the test teardown, use this in test case:
...               [Teardown] Do_Not_Start_Failing_If_This_Failed
...               If you do not want the test setup in a particular test, use this in the test case:
...               [Setup] Run_Even_When_Failing_Fast
...               If success of such "run even when failing" test case can return the system under test
...               back to corret state, call at the end of such test case this:
...               Do_Not_Fail_Fast_From_Now_On

*** Keywords ***
Do_Not_Fail_Fast_From_Now_On
    [Documentation]    Set suite to not fail fast.
    BuiltIn.Set_Suite_Variable    ${SuiteFastFail}    False

Fail_This_Fast_On_Previous_Error
    [Documentation]    Mark (immediately) this test case as failed when fast-fail is enabled in suite.
    BuiltIn.Run_Keyword_If    '''${SuiteFastFail}'''=='True'    BuiltIn.Fail    SKIPPED due to a failure in a previous fundamental test case.

Start_Failing_Fast_If_This_Failed
    [Documentation]    Set suite fail fast behavior on, if current test case has failed.
    BuiltIn.Run_Keyword_If_Test_Failed    BuiltIn.Set_Suite_Variable    ${SuiteFastFail}    True

Run_Even_When_Failing_Fast
    [Documentation]    This is just a more readable 'None' to override [Setup].
    BuiltIn.No_Operation

Do_Not_Start_Failing_If_This_Failed
    [Documentation]    This is just a more readable 'None' to override [Teardown].
    BuiltIn.No_Operation

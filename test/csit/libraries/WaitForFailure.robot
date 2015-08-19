*** Settings ***
Documentation     Robot keyword library (Resource) for catching a later failure in temporarily passing repeated check.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Terminology:
...               "cell_sequence" is a sequence of Robot cells, usually executable.
...               "keyword" is a first cell in that sequence, entry point of execution,
...               the item defined in Keywords table (or in library) which may take arguments (the rest of cell sequence).
...               "Keyword" may refer to keyword or executable cell sequence, or both, depending on context.

*** Keywords ***
Log_Failable_Keyword
    [Arguments]    @{cell_sequence}
    [Documentation]    Execute failable Keyword. Log the resulting value when it does not fail.
    ${result}=    BuiltIn.Run_Keyword    @{cell_sequence}
    BuiltIn.Log    ${result}
    [Return]    ${result}

Keyword_Should_Fail_In_Any_Way
    [Arguments]    @{cell_sequence}
    [Documentation]    Try to run the Keyword and Log the result. Pass and return the error on any failure, Fail otherwise.
    ${error}=    BuiltIn.Run_Keyword_And_Expect_Error    *    Log_Failable_Keyword    @{cell_sequence}
    # '*' means we really catch all types of errors.
    [Return]    ${error}

Confirm_Keyword_Fails_Within_Timeout
    [Arguments]    ${timeout}    ${refresh}    @{cell_list}
    [Documentation]    Some Keywords need several tries to finally fail, this keyword passes if and only if the failure ultimately happens.
    # Arguments with default values interact badly with varargs, so using WUKS argument style.
    ${error}=    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Keyword_Should_Fail_In_Any_Way    @{cell_list}

Verify_Keyword_Does_Not_Fail_Within_Timeout
    [Arguments]    ${timeout}    ${refresh}    @{cell_list}
    [Documentation]    Some checks report false success for a short time. This keyword verifies no failure does happen within timeout period.
    ...    This keyword does not report the return value of the cell list execution.
    BuiltIn.Run_Keyword_And_Expect_Error    *    Confirm_Keyword_Fails_Within_Timeout    ${timeout}    ${refresh}    @{cell_list}
    # TODO: '*' means we are not sure about formatting of ${timeout}. Check whether Robot can print it for us.

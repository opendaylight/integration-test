*** Settings ***
Documentation     Robot keyword Resource for catching a later failure in temporarily passing repeated check.
...
...               Copyright (c) 2015-2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Terminology:
...               "cell_sequence" is a sequence of Robot cells, usually executable.
...               "keyword_name" is a first cell in that sequence, entry point of execution,
...               the item defined in Keywords table (or in a Library or Resource)
...               which may take arguments (the rest of cell sequence).
...               Note that this may not work correctly with named arguments, due to ordering,
...               so positional cells are strongly suggested to be positional arguments.
...               "Keyword" or "keyword" may refer to keyword_name or executable cell sequence,
...               or both, depending on context.

*** Keywords ***
Log_Failable_Keyword
    [Arguments]    @{cell_sequence}
    [Documentation]    Execute failable Keyword. Log the resulting value when it does not fail.
    ...    Deprecated, was used in previous implementation of higher-level keywords.
    ${result} =    BuiltIn.Run_Keyword    @{cell_sequence}
    BuiltIn.Log    ${result}
    [Return]    ${result}

Keyword_Should_Fail_In_Any_Way
    [Arguments]    @{cell_sequence}
    [Documentation]    Try to run the Keyword and Log the result. Pass and return the error on any failure, Fail otherwise.
    ...    Deprecated, was used in previous implementation of higher-level keywords.
    ${error} =    BuiltIn.Run_Keyword_And_Expect_Error    *    Log_Failable_Keyword    @{cell_sequence}
    # '*' means we really catch all types of errors.
    [Return]    ${error}

Invert_Failure
    [Arguments]    @{cell_sequence}
    [Documentation]    The response of Keyword execution is either a return value or a failure message.
    ...    This keyword calls the argument keyword and returns its failure message string,
    ...    or fails with its return value converted to string.
    ${status}    ${output} =    BuiltIn.Run_Keyword_And_Ignore_Error    @{cell_sequence}
    BuiltIn.Run_Keyword_If    "${status}" != "PASS"    BuiltIn.Return_From_Keyword    ${output}
    ${output} =    BuiltIn.Convert_To_String    ${output}
    BuiltIn.Fail    ${output}

Confirm_Keyword_Fails_Within_Timeout
    [Arguments]    ${timeout}    ${refresh}    @{cell_list}
    [Documentation]    Some Keywords need several tries to finally fail, this keyword passes if and only if the failure ultimately happens.
    # Arguments with default values interact badly with varargs, so using WUKS argument style.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Invert_Failure    @{cell_list}

Verify_Keyword_Never_Passes_Within_Timeout
    [Arguments]    ${timeout}    ${refresh}    @{cell_list}
    [Documentation]    Some negative checks report false failure for a short time. This keyword verifies no pass does happen within timeout period.
    BuiltIn.Run_Keyword_And_Return    Invert_Failure    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    @{cell_list}

Verify_Keyword_Does_Not_Fail_Within_Timeout
    [Arguments]    ${timeout}    ${refresh}    @{cell_list}
    [Documentation]    Some positive checks report false success for a short time. This keyword verifies no failure does happen within timeout period.
    ...    This implementation needs more complicated logic than, Verify_Keyword_Never_Passes_Within_Timeout,
    ...    so use that keyword in case you have a negative check handy.
    BuiltIn.Run_Keyword_And_Return    Invert_Failure    Confirm_Keyword_Fails_Within_Timeout    ${timeout}    ${refresh}    @{cell_list}
    # TODO: Remove the added comment text of time running out to restore last Keyword return value.

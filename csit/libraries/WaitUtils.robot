*** Settings ***
Documentation     Robot keyword library (Resource) with several Keywords for monitoring and waiting.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               BuiltIn.Wait_Until_Keyword_Succeeds is useful in avoiding unnecessary sleeps.
...               But several usage cases need slightly different logic, here are Keywords for that.
...
...               This library uses ScalarClosures for plugging in specific Keywords.
...               Storing private state in suite variables is easy, but it can lead to hard-to-debug issues,
...               so this library tries to support explicit state passing.
...               Unfortunately, failing limits type of message to return,
...               so implementation of some Keywords looks quite convoluted.
...
...               Particular closures are to be given by caller:
...               Stateless Assertor: Take no arguments. Return comment or Fail with message.
...               Stateful Assertor: Take single ${state} argument. Return new state and comment, or Fail with message.
...               (Stateless) Getter: Take no argument. Return single scalar data, or Fail with message.
...               Stateless Validator: Take single ${data} argument. Return comment, or Fail with message.
...               (Unsafe) Stateful Validator: Take ${state} and ${data} arguments. Return new state and comment, or Fail with message.
...               Safe Stateful Validator: Take ${state} and ${data} arguments. Return new state, validation status and comment/message.
...               TODO: Create a dummy closure for each type to be used as default value?
...
...               TODO: Figure out a way to merge this with FaitForFailure.robot
...               TODO: Add Keywords that are Safe (return state, success and message)
...               so that callers do not need to refresh state explicitly.
Library           DateTime
Library           String
Resource          ${CURDIR}/ScalarClosures.robot

*** Keywords ***
WU_Setup
    [Documentation]    Call dependency setup. Perhaps needed.
    ScalarClosures.SC_Setup

Limiting_Stability_Safe_Stateful_Validator_As_Keyword
    [Arguments]    ${old_state}    ${data}    ${valid_minimum}=-1
    [Documentation]    Report failure if minimum not reached or data value changed from last time. Useful to become validator.
    ${new_state} =    BuiltIn.Set_Variable    ${data}
    BuiltIn.Return_From_Keyword_If    ${data} < ${valid_minimum}    ${new_state}    FAIL    Minimum not reached.
    BuiltIn.Return_From_Keyword_If    ${data} != ${old_state}    ${new_state}    FAIL    Data value has changed.
    [Return]    ${new_state}    PASS    Validated stable: ${data}

Create_Limiting_Stability_Safe_Stateful_Validator_From_Value_To_Overcome
    [Arguments]    ${maximum_invalid}=-1
    [Documentation]    Helper function to use if maximum invalid value (instead of minimum valid) is known.
    ${valid_minimum} =    BuiltIn.Evaluate    str(int(${maximum_invalid}) + 1)
    ${validator} =    ScalarClosures.Closure_From_Keyword_And_Arguments    WaitUtils.Limiting_Stability_Safe_Stateful_Validator_As_Keyword    state_holder    data_holder    valid_minimum=${valid_minimum}
    [Return]    ${validator}

Excluding_Stability_Safe_Stateful_Validator_As_Keyword
    [Arguments]    ${old_state}    ${data}    ${excluded_value}=-1
    [Documentation]    Report failure if got the excluded value or if data value changed from last time. Useful to become validator.
    ${new_state} =    BuiltIn.Set_Variable    ${data}
    BuiltIn.Return_From_Keyword_If    ${data} == ${excluded_value}    ${new_state}    FAIL    Got the excluded value.
    BuiltIn.Return_From_Keyword_If    ${data} != ${old_state}    ${new_state}    FAIL    Data value has changed.
    [Return]    ${new_state}    PASS    Validated stable: ${data}

WaitUtils__Check_Sanity_And_Compute_Derived_Times
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1
    [Documentation]    Common checks for argument values. Return times in seconds and deadline date implied by timeout time.
    # Sanity check ${count}.
    BuiltIn.Run_Keyword_If    int(${count}) < 1    BuiltIn.Fail    \${count} is ${count} and not at least 1.
    # Sanity check ${period}.
    ${period_in_seconds} =    DateTime.Convert_Time    ${period}    result_format=number
    BuiltIn.Run_Keyword_If    ${period_in_seconds} <= 0.0    BuiltIn.Fail    \${period} ${period} has to be positive.
    # Figure out deadline.
    ${date_now} =    DateTime.Get_Current_Date
    ${timeout_in_seconds} =    DateTime.Convert_Time    ${timeout}    result_format=number
    # In the following line, arguments have to be in order which is opposite to what name suggests.
    ${date_deadline} =    DateTime.Add_Time_To_Date    ${date_now}    ${timeout_in_seconds}
    [Return]    ${timeout_in_seconds}    ${period_in_seconds}    ${date_deadline}

WaitUtils__Is_Deadline_Reachable
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${sleeps_left}=1    ${message}=No attempt made.
    [Documentation]    Compute time to be wasted in sleeps, compare to deadline. Fail with message when needed.
    # FIXME: Sensible default for deadline?
    ${date_now} =    DateTime.Get_Current_Date
    ${time_deadline} =    DateTime.Subtract_Date_From_Date    ${date_deadline}    ${date_now}    result_format=number
    ${time_minimal} =    BuiltIn.Evaluate    int(${sleeps_left}) * ${period_in_seconds}
    BuiltIn.Run_Keyword_If    ${time_minimal} >= ${time_deadline}    BuiltIn.Fail    Not possible to succeed within the deadline. ${message}

Stateless_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${count}=1    ${assertor}=${ScalarClosures__fail}
    [Documentation]    Pass only if ${assertor} passes ${count} times in a row with ${period_in_seconds} between attempts; less standard arguments.
    ${result} =    BuiltIn.Set_Variable    No result yet.
    # Do we have enough time to succeed?
    ${sleeps} =    BuiltIn.Evaluate    ${count} - 1
    WaitUtils__Is_Deadline_Reachable    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}    sleeps_left=${sleeps}    message=Last result: ${result}
    # Entering the main loop.
    : FOR    ${sleeps_left}    IN RANGE    ${count}-1    -1    -1    # If count is 3, for will go through 2, 1, and 0.
    \    # Run the assertor and collect the garbage.
    \    ${result} =    ScalarClosures.Run_Keyword_And_Collect_Garbage    ScalarClosures.Run_Closure_As_Is    ${assertor}
    \    # We have not failed yet. Was this the final try?
    \    BuiltIn.Return_From_Keyword_If    ${sleeps_left} <= 0    ${result}
    \    # Is there enough time left?
    \    WaitUtils__Is_Deadline_Reachable    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}    sleeps_left=${sleeps_left}    message=Last result: ${result}
    \    # We will do next try, byt we have to sleep before.
    \    BuiltIn.Sleep    ${period_in_seconds} s
    BuiltIn.Fail    Logic error, we should have returned before.

Stateless_Assert_Closure_Has_To_Succeed_Consecutively
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${assertor}=${ScalarClosures__fail}
    [Documentation]    Pass only if ${assertor} passes ${count} times in a row with ${period} between attempts; standard arguments.
    # TODO: Put default values into variables for users to override at pybot invocation?
    ${timeout_in_seconds}    ${period_in_seconds}    ${date_deadline} =    WaitUtils__Check_Sanity_And_Compute_Derived_Times    timeout=${timeout}    period=${period}    count=${count}
    ${result} =    Stateless_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}    count=${count}    assertor=${assertor}
    [Return]    ${result}

Stateful_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${count}=1    ${assertor}=${ScalarClosures__fail}    ${initial_state}=${None}
    [Documentation]    Pass only if ${assertor} passes ${count} times in a row with ${period} between attempts. Keep assertor state in local variable. Less standard arguments.
    # TODO: Put default values into variables for users to override.
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # Do we have enough time to succeed?
    ${sleeps} =    BuiltIn.Evaluate    ${count} - 1
    WaitUtils__Is_Deadline_Reachable    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}    sleeps_left=${sleeps}    message=Last result: ${result}
    # Entering the main loop.
    : FOR    ${sleeps_left}    IN RANGE    ${count}-1    -1    -1
    \    ${state}    ${result} =    ScalarClosures.Run_Keyword_And_Collect_Garbage    ScalarClosures.Run_Closure_After_Replacing_First_Argument    ${assertor}    ${state}
    \    # We have not failed yet. Was this the final try?
    \    BuiltIn.Return_From_Keyword_If    ${sleeps_left} <= 0    ${result}
    \    # Is there enough time left?
    \    WaitUtils__Is_Deadline_Reachable    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}    sleeps_left=${sleeps_left}    message=Last result: ${result}
    \    # We will do next try, byt we have to sleep before.
    \    BuiltIn.Sleep    ${period_in_seconds} s
    BuiltIn.Fail    Logic error, we should have returned before.

Stateful_Assert_Closure_Has_To_Succeed_Consecutively
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${assertor}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    [Documentation]    Pass only if ${assertor} passes ${count} times in a row with ${period} between attempts. Keep assertor state in local variable. Standard arguments.
    # TODO: Put default values into variables for users to override.
    ${timeout_in_seconds}    ${period_in_seconds}    ${date_deadline} =    WaitUtils__Check_Sanity_And_Compute_Derived_Times    timeout=${timeout}    period=${period}    count=${count}
    ${result} =    Stateful_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}    count=${count}    assertor=${assertor}    initial_state=${initial_state}
    [Return]    ${result}

Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${count}=1    ${getter}=${ScalarClosures__fail}    ${safe_validator}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    [Documentation]    Pass only if consecutively ${count} times in a row with ${period} between attempts: ${getter} creates data and ${safe_validator} passes. Validator updates its state even if it reports failure. Always return validator state, status and message.
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # Do we have enough time to succeed?
    ${sleeps} =    BuiltIn.Evaluate    ${count} - 1
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    WaitUtils__Is_Deadline_Reachable    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}    sleeps_left=${sleeps}
    ...    message=Last result: ${result}
    BuiltIn.Return_From_Keyword_If    '''${status}''' != '''PASS'''    ${state}    ${status}    ${message}
    # Entering the main loop.
    : FOR    ${sleeps_left}    IN RANGE    ${count}-1    -1    -1
    \    # Getter may fail, but this Keyword should return state, so we need RKAIE.
    \    ${status}    ${data} =    BuiltIn.Run_Keyword_And_Ignore_Error    ScalarClosures.Run_Keyword_And_Collect_Garbage    ScalarClosures.Run_Closure_As_Is    ${getter}
    \    BuiltIn.Return_From_Keyword_If    '''${status}''' != '''PASS'''    ${state}    ${status}    Getter failed: ${data}
    \    # Is there enough time left?
    \    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    WaitUtils__Is_Deadline_Reachable    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}
    \    ...    sleeps_left=${sleeps_left}    message=Last result: ${result}
    \    BuiltIn.Return_From_Keyword_If    '''${status}''' != '''PASS'''    ${state}    ${status}    ${message}
    \    ${state}    ${status}    ${result} =    ScalarClosures.Run_Keyword_And_Collect_Garbage    ScalarClosures.Run_Closure_After_Replacing_First_Two_Arguments    ${safe_validator}
    \    ...    ${state}    ${data}
    \    # Validator may have reported failure.
    \    BuiltIn.Return_From_Keyword_If    '''${status}''' != '''PASS'''    ${state}    ${status}    Validator failed: ${result}
    \    # Was this the final try?
    \    BuiltIn.Return_From_Keyword_If    ${sleeps_left} <= 0    ${state}    ${status}    ${result}
    \    # Is there enough time left?
    \    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    WaitUtils__Is_Deadline_Reachable    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}
    \    ...    sleeps_left=${sleeps_left}    message=Last result: ${result}
    \    BuiltIn.Return_From_Keyword_If    '''${status}''' != '''PASS'''    ${state}    ${status}    ${message}
    \    # We will do next try, byt we have to sleep before.
    \    BuiltIn.Sleep    ${period_in_seconds} s
    BuiltIn.Fail    Logic error, we should have returned before.

Propagate_Fail_If_Message_Starts_With_Prefix
    [Arguments]    ${message}=${EMPTY}    ${prefix}=magic
    [Documentation]    Helper keyword to distinguish escalable failures by their prefix. If it is escalable, Fail without changing the message; otherwise Return comment.
    # TODO: Move to a more appropriate Resource.
    # Empty message cannot fit prefix.
    ${status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Be_Empty    ${message}
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'    Got empty message.
    # Is there anything except the prefix?
    @{message_chunks}=    String.Split_String    ${message}    ${prefix}
    # If there is something at the first chunk, the prefix was not at start.
    ${status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Be_Empty    ${message_chunks[0]}
    BuiltIn.Return_From_Keyword_If    '${status}' != 'PASS'    ${message} does not start with ${prefix}
    # We got the fail to propagate
    BuiltIn.Fail    ${message}

Wait_For_Getter_And_Safe_Stateful_Validator_Consecutive_Success
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${getter}=${ScalarClosures__fail}    ${safe_validator}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    [Documentation]    Analogue of Wait Until Keyword Succeeds, but it passes state of validator around. Calls GASSVHTSCBD to verify data is "stable".
    # FIXME: Document that Safe Stateful Validator has to return state, status and message (and never fail)
    ${timeout_in_seconds}    ${period_in_seconds}    ${date_deadline} =    WaitUtils__Check_Sanity_And_Compute_Derived_Times    timeout=${timeout}    period=${period}    count=${count}
    # Maximum number of tries. TODO: Move to separate Keyword?
    ${maximum_tries} =    BuiltIn.Evaluate    math.ceil(${timeout_in_seconds} / ${period_in_seconds})    modules=math
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # The loop for failures.
    : FOR    ${try}    IN RANGE    1    ${maximum_tries}+1    # If maximum_tries is 3, for will go through 1, 2, and 3.
    \    ${state}    ${status}    ${result} =    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}
    \    ...    count=${count}    getter=${getter}    safe_validator=${safe_validator}    initial_state=${state}
    \    # Have we passed?
    \    BuiltIn.Return_From_Keyword_If    '''${status}''' == '''PASS'''    ${result}
    \    # Are we out of time?
    \    Propagate_Fail_If_Message_Starts_With_Prefix    ${result}    Not possible to succeed within the deadline.
    \    # We will do next try, but we have to sleep before.
    \    BuiltIn.Sleep    ${period_in_seconds} s
    BuiltIn.Fail    Logic error, we should have returned before.

Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${getter}=${ScalarClosures__fail}    ${safe_validator}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    [Documentation]    Analogue of Wait Until Keyword Succeeds, but it passes state of validator around and exits early on getter failure. Calls GASSVHTSCBD to verify data is "stable".
    # If this ever fails, we want to know the exact inputs passed to it.
    ${tmp}=    BuiltIn.Evaluate    int(${count})
    BuiltIn.Log    count=${tmp}
    ${timeout_in_seconds}    ${period_in_seconds}    ${date_deadline} =    WaitUtils__Check_Sanity_And_Compute_Derived_Times    timeout=${timeout}    period=${period}    count=${count}
    # Maximum number of tries. TODO: Move to separate Keyword or add into CSACDT?
    ${maximum_tries} =    BuiltIn.Evaluate    math.ceil(${timeout_in_seconds} / ${period_in_seconds})    modules=math
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # The loop for failures.
    : FOR    ${try}    IN RANGE    1    ${maximum_tries}+1    # If maximum_tries is 3, for will go through 1, 2, and 3.
    \    ${state}    ${status}    ${result} =    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=${period_in_seconds}
    \    ...    count=${count}    getter=${getter}    safe_validator=${safe_validator}    initial_state=${state}
    \    # Have we passed?
    \    BuiltIn.Return_From_Keyword_If    '''${status}''' == '''PASS'''    ${result}
    \    # Are we out of time? Look at ${result}.
    \    Propagate_Fail_If_Message_Starts_With_Prefix    ${result}    Not possible to succeed within the deadline.
    \    # Now check for getter error, by analysing ${result}.
    \    Propagate_Fail_If_Message_Starts_With_Prefix    ${result}    Getter failed
    \    # We can do the next try, byt we have to sleep before.
    \    BuiltIn.Sleep    ${period_in_seconds} s
    BuiltIn.Fail    Logic error, we should have returned before.

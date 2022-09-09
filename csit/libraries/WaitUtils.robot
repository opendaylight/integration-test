*** Settings ***
Documentation       Robot keyword library (Resource) with several Keywords for monitoring and waiting.
...
...                 Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 BuiltIn.Wait_Until_Keyword_Succeeds has two possible results: Fast pass or fail on timeout.
...                 Generally, keywords in this Resource also allow for some kind of fast failure condition.
...                 This usually requires more than a single keyword to run inside the iteration loop.
...                 This library uses ScalarClosures for plugging in specific (multiple) Keywords.
...
...                 Storing private state in suite variables is easy, but it can lead to hard-to-debug issues,
...                 so this library tries to support explicit state passing.
...                 Unfortunately, failing limits type of message to return,
...                 so implementation of some Keywords looks quite convoluted.
...
...                 Particular closures are to be given by caller:
...                 Stateless Assertor: Take no arguments. Return comment or Fail with message.
...                 Stateful Assertor: Take single ${state} argument. Return new state and comment, or Fail with message.
...                 (Stateless) Getter: Take no argument. Return single scalar data, or Fail with message.
...                 Stateless Validator: Take single ${data} argument. Return comment, or Fail with message.
...                 (Unsafe) Stateful Validator: Take ${state} and ${data} arguments. Return new state and comment, or Fail with message.
...                 Safe Stateful Validator: Take ${state} and ${data} arguments. Return new state, validation status and comment/message.
...                 TODO: Create a dummy closure for each type to be used as default value?
...
...                 TODO: Figure out a way to merge this with WaitForFailure.robot
...                 TODO: Add Keywords that are Safe (return state, success and message)
...                 so that callers do not need to refresh state explicitly.

Library             DateTime
Library             String
Resource            ${CURDIR}/ScalarClosures.robot


*** Keywords ***
WU_Setup
    [Documentation]    Call dependency setup. Perhaps needed.
    ScalarClosures.SC_Setup

Limiting_Stability_Safe_Stateful_Validator_As_Keyword
    [Documentation]    Report failure if minimum not reached or data value changed from last time. Useful to become validator.
    [Arguments]    ${old_state}    ${data}    ${valid_minimum}=-1
    ${new_state} =    BuiltIn.Set_Variable    ${data}
    IF    ${data} < ${valid_minimum}
        RETURN    ${new_state}    FAIL    Minimum not reached.
    END
    IF    ${data} != ${old_state}
        RETURN    ${new_state}    FAIL    Data value has changed.
    END
    RETURN    ${new_state}    PASS    Validated stable: ${data}

Create_Limiting_Stability_Safe_Stateful_Validator_From_Value_To_Overcome
    [Documentation]    Helper function to use if maximum invalid value (instead of minimum valid) is known.
    [Arguments]    ${maximum_invalid}=-1
    ${valid_minimum} =    BuiltIn.Evaluate    str(int(${maximum_invalid}) + 1)
    ${validator} =    ScalarClosures.Closure_From_Keyword_And_Arguments
    ...    WaitUtils.Limiting_Stability_Safe_Stateful_Validator_As_Keyword
    ...    state_holder
    ...    data_holder
    ...    valid_minimum=${valid_minimum}
    RETURN    ${validator}

Excluding_Stability_Safe_Stateful_Validator_As_Keyword
    [Documentation]    Report failure if got the excluded value or if data value changed from last time. Useful to become validator.
    [Arguments]    ${old_state}    ${data}    ${excluded_value}=-1
    ${new_state} =    BuiltIn.Set_Variable    ${data}
    IF    ${data} == ${excluded_value}
        RETURN    ${new_state}    FAIL    Got the excluded value.
    END
    IF    ${data} != ${old_state}
        RETURN    ${new_state}    FAIL    Data value has changed.
    END
    RETURN    ${new_state}    PASS    Validated stable: ${data}

WaitUtils__Check_Sanity_And_Compute_Derived_Times
    [Documentation]    Common checks for argument values. Return times in seconds and deadline date implied by timeout time.
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1
    # Sanity check ${count}.
    IF    int(${count}) < 1
        BuiltIn.Fail    \${count} is ${count} and not at least 1.
    END
    # Sanity check ${period}.
    ${period_in_seconds} =    DateTime.Convert_Time    ${period}    result_format=number
    IF    ${period_in_seconds} <= 0.0
        BuiltIn.Fail    \${period} ${period} has to be positive.
    END
    # Figure out deadline.
    ${date_now} =    DateTime.Get_Current_Date
    ${timeout_in_seconds} =    DateTime.Convert_Time    ${timeout}    result_format=number
    # In the following line, arguments have to be in order which is opposite to what name suggests.
    ${date_deadline} =    DateTime.Add_Time_To_Date    ${date_now}    ${timeout_in_seconds}
    RETURN    ${timeout_in_seconds}    ${period_in_seconds}    ${date_deadline}

WaitUtils__Is_Deadline_Reachable
    [Documentation]    Compute time to be wasted in sleeps, compare to deadline. Fail with message when needed.
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${sleeps_left}=1    ${message}=No attempt made.
    # FIXME: Sensible default for deadline?
    ${date_now} =    DateTime.Get_Current_Date
    ${time_deadline} =    DateTime.Subtract_Date_From_Date    ${date_deadline}    ${date_now}    result_format=number
    ${time_minimal} =    BuiltIn.Evaluate    int(${sleeps_left}) * ${period_in_seconds}
    IF    ${time_minimal} >= ${time_deadline}
        BuiltIn.Fail    Not possible to succeed within the deadline. ${message}
    END

Wait_For_Getter_Failure_Or_Stateless_Validator_Pass
    [Documentation]    Repeatedly run getter and plug its output to validator. If both pass, return validator message.
    ...    If getter fails, fail. If validator fails, repeat in WUKS fashion (fail when timeout is exceeded).
    ...    FIXME: Cover this keyword in WaitUtilTest.robot
    [Arguments]    ${timeout}=60s    ${period}=1s    ${getter}=${ScalarClosures__fail}    ${stateless_validator}=${ScalarClosures__identity}
    ${timeout_in_seconds}
    ...    ${period_in_seconds}
    ...    ${date_deadline} =
    ...    WaitUtils__Check_Sanity_And_Compute_Derived_Times
    ...    timeout=${timeout}
    ...    period=${period}
    ${iterations} =    BuiltIn.Evaluate    ${timeout_in_seconds} / ${period_in_seconds}
    FOR    ${i}    IN RANGE    ${iterations}
        ${data} =    ScalarClosures.Run_Keyword_And_Collect_Garbage    ScalarClosures.Run_Closure_As_Is    ${getter}
        ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    ScalarClosures.Run_Keyword_And_Collect_Garbage
        ...    ScalarClosures.Run_Closure_After_Replacing_First_Argument
        ...    ${stateless_validator}
        ...    ${data}
        IF    "${status}" == "PASS"    RETURN    ${message}
        WaitUtils__Is_Deadline_Reachable
        ...    date_deadline=${date_deadline}
        ...    period_in_seconds=${period_in_seconds}
        ...    message=Last validator message: ${message}
        BuiltIn.Sleep    ${period_in_seconds} s
    END
    BuiltIn.Fail    Logic error, we should have returned before.

Stateless_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline
    [Documentation]    Pass only if \${assertor} passes ${count} times in a row with ${period_in_seconds} between attempts; less standard arguments.
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${count}=1    ${assertor}=${ScalarClosures__fail}
    ${result} =    BuiltIn.Set_Variable    No result yet.
    # Do we have enough time to succeed?
    ${sleeps} =    BuiltIn.Evaluate    ${count} - 1
    WaitUtils__Is_Deadline_Reachable
    ...    date_deadline=${date_deadline}
    ...    period_in_seconds=${period_in_seconds}
    ...    sleeps_left=${sleeps}
    ...    message=Last result: ${result}
    # Entering the main loop.
    FOR    ${sleeps_left}    IN RANGE    ${count}-1    -1    -1    # If count is 3, for will go through 2, 1, and 0.
        # Run the assertor and collect the garbage.
        ${result} =    ScalarClosures.Run_Keyword_And_Collect_Garbage
        ...    ScalarClosures.Run_Closure_As_Is
        ...    ${assertor}
        # We have not failed yet. Was this the final try?
        IF    ${sleeps_left} <= 0    RETURN    ${result}
        # Is there enough time left?
        WaitUtils__Is_Deadline_Reachable
        ...    date_deadline=${date_deadline}
        ...    period_in_seconds=${period_in_seconds}
        ...    sleeps_left=${sleeps_left}
        ...    message=Last result: ${result}
        # We will do next try, byt we have to sleep before.
        BuiltIn.Sleep    ${period_in_seconds} s
    END
    BuiltIn.Fail    Logic error, we should have returned before.

Stateless_Assert_Closure_Has_To_Succeed_Consecutively
    [Documentation]    Pass only if \${assertor} passes ${count} times in a row with ${period} between attempts; standard arguments.
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${assertor}=${ScalarClosures__fail}
    # TODO: Put default values into variables for users to override at pybot invocation?
    ${timeout_in_seconds}
    ...    ${period_in_seconds}
    ...    ${date_deadline} =
    ...    WaitUtils__Check_Sanity_And_Compute_Derived_Times
    ...    timeout=${timeout}
    ...    period=${period}
    ...    count=${count}
    ${result} =    Stateless_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline
    ...    date_deadline=${date_deadline}
    ...    period_in_seconds=${period_in_seconds}
    ...    count=${count}
    ...    assertor=${assertor}
    RETURN    ${result}

Stateful_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline
    [Documentation]    Pass only if $\{assertor} passes ${count} times in a row with ${period} between attempts. Keep assertor state in local variable. Less standard arguments.
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${count}=1    ${assertor}=${ScalarClosures__fail}    ${initial_state}=${None}
    # TODO: Put default values into variables for users to override.
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # Do we have enough time to succeed?
    ${sleeps} =    BuiltIn.Evaluate    ${count} - 1
    WaitUtils__Is_Deadline_Reachable
    ...    date_deadline=${date_deadline}
    ...    period_in_seconds=${period_in_seconds}
    ...    sleeps_left=${sleeps}
    ...    message=Last result: ${result}
    # Entering the main loop.
    FOR    ${sleeps_left}    IN RANGE    ${count}-1    -1    -1
        ${state}    ${result} =    ScalarClosures.Run_Keyword_And_Collect_Garbage
        ...    ScalarClosures.Run_Closure_After_Replacing_First_Argument
        ...    ${assertor}
        ...    ${state}
        # We have not failed yet. Was this the final try?
        IF    ${sleeps_left} <= 0    RETURN    ${result}
        # Is there enough time left?
        WaitUtils__Is_Deadline_Reachable
        ...    date_deadline=${date_deadline}
        ...    period_in_seconds=${period_in_seconds}
        ...    sleeps_left=${sleeps_left}
        ...    message=Last result: ${result}
        # We will do next try, byt we have to sleep before.
        BuiltIn.Sleep    ${period_in_seconds} s
    END
    BuiltIn.Fail    Logic error, we should have returned before.

Stateful_Assert_Closure_Has_To_Succeed_Consecutively
    [Documentation]    Pass only if \${assertor} passes ${count} times in a row with ${period} between attempts. Keep assertor state in local variable. Standard arguments.
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${assertor}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    # TODO: Put default values into variables for users to override.
    ${timeout_in_seconds}
    ...    ${period_in_seconds}
    ...    ${date_deadline} =
    ...    WaitUtils__Check_Sanity_And_Compute_Derived_Times
    ...    timeout=${timeout}
    ...    period=${period}
    ...    count=${count}
    ${result} =    Stateful_Assert_Closure_Has_To_Succeed_Consecutively_By_Deadline
    ...    date_deadline=${date_deadline}
    ...    period_in_seconds=${period_in_seconds}
    ...    count=${count}
    ...    assertor=${assertor}
    ...    initial_state=${initial_state}
    RETURN    ${result}

Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline
    [Documentation]    Pass only if consecutively ${count} times in a row with ${period} between attempts: \${getter} creates data and \${safe_validator} passes. Validator updates its state even if it reports failure. Always return validator state, status and message.
    [Arguments]    ${date_deadline}=0    ${period_in_seconds}=1    ${count}=1    ${getter}=${ScalarClosures__fail}    ${safe_validator}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # Do we have enough time to succeed?
    ${sleeps} =    BuiltIn.Evaluate    ${count} - 1
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    WaitUtils__Is_Deadline_Reachable
    ...    date_deadline=${date_deadline}
    ...    period_in_seconds=${period_in_seconds}
    ...    sleeps_left=${sleeps}
    ...    message=Last result: ${result}
    IF    '''${status}''' != '''PASS'''
        RETURN    ${state}    ${status}    ${message}
    END
    # Entering the main loop.
    FOR    ${sleeps_left}    IN RANGE    ${count}-1    -1    -1
        # Getter may fail, but this Keyword should return state, so we need RKAIE.
        ${status}    ${data} =    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    ScalarClosures.Run_Keyword_And_Collect_Garbage
        ...    ScalarClosures.Run_Closure_As_Is
        ...    ${getter}
        IF    '''${status}''' != '''PASS'''
            RETURN...    '''${status}''' != '''PASS'''
            ...    ${state}
            ...    ${status}
            ...    Getter failed: ${data}
        END
        # Is there enough time left?
        ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    WaitUtils__Is_Deadline_Reachable
        ...    date_deadline=${date_deadline}
        ...    period_in_seconds=${period_in_seconds}
        ...    sleeps_left=${sleeps_left}
        ...    message=Last result: ${result}
        IF    '''${status}''' != '''PASS'''
            RETURN    ${state}    ${status}    ${message}
        END
        ${state}    ${status}    ${result} =    ScalarClosures.Run_Keyword_And_Collect_Garbage
        ...    ScalarClosures.Run_Closure_After_Replacing_First_Two_Arguments
        ...    ${safe_validator}
        ...    ${state}
        ...    ${data}
        # Validator may have reported failure.
        IF    '''${status}''' != '''PASS'''
            RETURN...    '''${status}''' != '''PASS'''
            ...    ${state}
            ...    ${status}
            ...    Validator failed: ${result}
        END
        # Was this the final try?
        IF    ${sleeps_left} <= 0
            RETURN    ${state}    ${status}    ${result}
        END
        # Is there enough time left?
        ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    WaitUtils__Is_Deadline_Reachable
        ...    date_deadline=${date_deadline}
        ...    period_in_seconds=${period_in_seconds}
        ...    sleeps_left=${sleeps_left}
        ...    message=Last result: ${result}
        IF    '''${status}''' != '''PASS'''
            RETURN    ${state}    ${status}    ${message}
        END
        # We will do next try, byt we have to sleep before.
        BuiltIn.Sleep    ${period_in_seconds} s
    END
    BuiltIn.Fail    Logic error, we should have returned before.

Propagate_Fail_If_Message_Starts_With_Prefix
    [Documentation]    Helper keyword to distinguish escalable failures by their prefix. If it is escalable, Fail without changing the message; otherwise Return comment.
    [Arguments]    ${message}=${EMPTY}    ${prefix}=magic
    # TODO: Move to a more appropriate Resource.
    # Empty message cannot fit prefix.
    ${status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Be_Empty    ${message}
    IF    '${status}' == 'PASS'    RETURN    Got empty message.
    # Is there anything except the prefix?
    @{message_chunks} =    String.Split_String    ${message}    ${prefix}
    # If there is something at the first chunk, the prefix was not at start.
    ${status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Be_Empty    ${message_chunks[0]}
    IF    '${status}' != 'PASS'
        RETURN    ${message} does not start with ${prefix}
    END
    # We got the fail to propagate
    BuiltIn.Fail    ${message}

Wait_For_Getter_And_Safe_Stateful_Validator_Consecutive_Success
    [Documentation]    Analogue of Wait Until Keyword Succeeds, but it passes state of validator around. Calls GASSVHTSCBD to verify data is "stable".
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${getter}=${ScalarClosures__fail}    ${safe_validator}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    # FIXME: Document that Safe Stateful Validator has to return state, status and message (and never fail)
    ${timeout_in_seconds}
    ...    ${period_in_seconds}
    ...    ${date_deadline} =
    ...    WaitUtils__Check_Sanity_And_Compute_Derived_Times
    ...    timeout=${timeout}
    ...    period=${period}
    ...    count=${count}
    # Maximum number of sleeps. TODO: Move to separate Keyword?
    ${maximum_sleeps} =    BuiltIn.Evaluate
    ...    math.ceil(${timeout_in_seconds} / ${period_in_seconds}) + 1
    ...    modules=math
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # The loop for failures.
    FOR    ${try}    IN RANGE    1    ${maximum_sleeps}+2    # If maximum_sleeps is 2, for will go through 1, 2, and 3.
        ${state}
        ...    ${status}
        ...    ${result} =
        ...    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline
        ...    date_deadline=${date_deadline}
        ...    period_in_seconds=${period_in_seconds}
        ...    count=${count}
        ...    getter=${getter}
        ...    safe_validator=${safe_validator}
        ...    initial_state=${state}
        # Have we passed?
        IF    '''${status}''' == '''PASS'''    RETURN    ${result}
        # Are we out of time?
        Propagate_Fail_If_Message_Starts_With_Prefix    ${result}    Not possible to succeed within the deadline.
        # We will do next try, but we have to sleep before.
        BuiltIn.Sleep    ${period_in_seconds} s
    END
    BuiltIn.Fail    Logic error, we should have returned before.

Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success
    [Documentation]    Analogue of Wait Until Keyword Succeeds, but it passes state of validator around and exits early on getter failure. Calls GASSVHTSCBD to verify data is "stable".
    [Arguments]    ${timeout}=60s    ${period}=1s    ${count}=1    ${getter}=${ScalarClosures__fail}    ${safe_validator}=${ScalarClosures__fail}    ${initial_state}=${NONE}
    # If this ever fails, we want to know the exact inputs passed to it.
    ${tmp} =    BuiltIn.Evaluate    int(${count})
    BuiltIn.Log    count=${tmp}
    ${timeout_in_seconds}
    ...    ${period_in_seconds}
    ...    ${date_deadline} =
    ...    WaitUtils__Check_Sanity_And_Compute_Derived_Times
    ...    timeout=${timeout}
    ...    period=${period}
    ...    count=${count}
    # Maximum number of sleeps. TODO: Move to separate Keyword or add into CSACDT?
    ${maximum_sleeps} =    BuiltIn.Evaluate    math.ceil(${timeout_in_seconds} / ${period_in_seconds})    modules=math
    ${result} =    BuiltIn.Set_Variable    No result yet.
    ${state} =    BuiltIn.Set_Variable    ${initial_state}
    # The loop for failures.
    FOR    ${try}    IN RANGE    1    ${maximum_sleeps}+2    # If maximum_sleeps is 2, for will go through 1, 2, and 3.
        ${state}
        ...    ${status}
        ...    ${result} =
        ...    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline
        ...    date_deadline=${date_deadline}
        ...    period_in_seconds=${period_in_seconds}
        ...    count=${count}
        ...    getter=${getter}
        ...    safe_validator=${safe_validator}
        ...    initial_state=${state}
        # Have we passed?
        IF    '''${status}''' == '''PASS'''    RETURN    ${result}
        # Are we out of time? Look at ${result}.
        Propagate_Fail_If_Message_Starts_With_Prefix    ${result}    Not possible to succeed within the deadline.
        # Now check for getter error, by analysing ${result}.
        Propagate_Fail_If_Message_Starts_With_Prefix    ${result}    Getter failed
        # We can do the next try, byt we have to sleep before.
        BuiltIn.Sleep    ${period_in_seconds} s
    END
    BuiltIn.Fail    Logic error, we should have returned before.

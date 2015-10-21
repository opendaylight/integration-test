*** Settings ***
Documentation     Unit test suite to WaitUtils library.
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
Suite Setup       WUT_Setup
Library           Collections
Resource          ${CURDIR}/../../../libraries/ScalarClosures.robot
Resource          ${CURDIR}/../../../libraries/WaitUtils.robot

*** Variables ***
${suite_scenario}    ${EMPTY}    # Used to store state for fake stateless getter.
@{stability_scenario}    -1    -1    0    0    1    2    2

*** Test Cases ***
SlACHTSC_Happy
    [Documentation]    Assertor always passes, we see its value returned.
    ${result} =    WaitUtils.Stateless_Assert_Closure_Has_To_Succeed_Consecutively    timeout=1.4s    period=0.5s    count=3    assertor=${ScalarClosures__identity}
    BuiltIn.Should_Be_Equal    ${result}    placeholder

SlACHTSC_Too_Many_Sleeps
    [Documentation]    There are too many sleeps to meet deadline.
    # TODO: Do we want the test to be this sensitive to failure message?
    BuiltIn.Run_Keyword_And_Expect_Error    Not possible to succeed within the deadline. Last result: No result yet.    WaitUtils.Stateless_Assert_Closure_Has_To_Succeed_Consecutively    timeout=1.4s    period=0.5s    count=4    assertor=${ScalarClosures__identity}

SlACHTSC_Slow_Assertor
    [Documentation]    Assertor takes additional time, deadline is encountered.
    ${assertor} =    ScalarClosures.Closure_From_Keyword_And_Arguments    BuiltIn.Sleep    0.3s
    BuiltIn.Run_Keyword_And_Expect_Error    Not possible to succeed within the deadline. Last result: None    WaitUtils.Stateless_Assert_Closure_Has_To_Succeed_Consecutively    timeout=1.4s    period=0.5s    count=3    assertor=${assertor}

SfACHTSC_Happy
    [Documentation]    Assertor succeeds just the right amount of counts.
    ${result} =    WaitUtils.Stateful_Assert_Closure_Has_To_Succeed_Consecutively    timeout=1.4s    period=0.5s    count=3    assertor=${countdown_quick}    initial_state=3
    BuiltIn.Should_Be_Equal    ${result}    still_alive

SfACHTSC_Too_Many_Sleeps
    [Documentation]    There are too many sleeps to meet deadline.
    BuiltIn.Run_Keyword_And_Expect_Error    Not possible to succeed within the deadline. Last result: No result yet.    WaitUtils.Stateful_Assert_Closure_Has_To_Succeed_Consecutively    timeout=1.4s    period=0.5s    count=4    assertor=${countdown_quick}
    ...    initial_state=4

SfACHTSC_Slow_Assertor
    [Documentation]    Assertor takes additional time, deadline is encountered.
    BuiltIn.Run_Keyword_And_Expect_Error    Not possible to succeed within the deadline. Last result: still_alive    WaitUtils.Stateful_Assert_Closure_Has_To_Succeed_Consecutively    timeout=1.4s    period=0.5s    count=3    assertor=${countdown_slow}
    ...    initial_state=3

SfACHTSC_Too_Few_Counts
    [Documentation]    Assertor fails at the last try.
    BuiltIn.Run_Keyword_And_Expect_Error    Count is down.    WaitUtils.Stateful_Assert_Closure_Has_To_Succeed_Consecutively    timeout=1.4s    period=0.5s    count=3    assertor=${countdown_quick}
    ...    initial_state=2

Fake_Getter_Fails_Exactly
    [Documentation]    Tests that fake getter created in this suite succeed exactly the right amount of times.
    # Named arguments are mandatory, otherwise positional values will be understood as them.
    ${value_list} =    BuiltIn.Set_Variable    0    0
    ${getter} =    Create_Scenario_Getter_Closure    ${value_list}    delay=0s    fail_on_negative=False
    ${data} =    ScalarClosures.Run_Closure_As_Is    ${getter}
    BuiltIn.Should_Be_Equal    ${data}    0
    ${data} =    ScalarClosures.Run_Closure_As_Is    ${getter}
    BuiltIn.Should_Be_Equal    ${data}    0
    BuiltIn.Run_Keyword_And_Expect_Error    IndexError: Given index 0 is out of the range 0--1.    ScalarClosures.Run_Closure_As_Is    ${getter}

Fake_Getter_Fails_On_Negative
    [Documentation]    Tests that fake getter created in this suite succeed exactly the right amount of times.
    # Named arguments are mandatory, otherwise positional values will be understood as them.
    ${value_list} =    BuiltIn.Set_Variable    0    -1
    ${getter} =    Create_Scenario_Getter_Closure    ${value_list}    delay=0s    fail_on_negative=True
    ${data} =    ScalarClosures.Run_Closure_As_Is    ${getter}
    BuiltIn.Should_Be_Equal    ${data}    0
    BuiltIn.Run_Keyword_And_Expect_Error    Got negative -1    ScalarClosures.Run_Closure_As_Is    ${getter}

GASSVHTSCBD_Happy
    [Documentation]    Set getter to report stable data and validator to see them as such.
    ${value_list} =    BuiltIn.Set_Variable    1    1    1
    ${getter} =    Create_Scenario_Getter_Closure    ${value_list}    delay=0s    fail_on_negative=True
    ${date_now} =    DateTime.Get_Current_Date
    ${date_deadline} =    DateTime.Add_Time_To_Date    ${date_now}    1.35
    ${state}    ${status}    ${result} =    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=0.4    count=3
    ...    getter=${getter}    safe_validator=${standard_validator}    initial_state=1
    BuiltIn.Should_Be_Equal    ${state}    1
    BuiltIn.Should_Be_Equal    ${status}    PASS
    BuiltIn.Should_Be_Equal    ${result}    Validated stable: 1

GASSVHTSCBD_Sleeps_Too_Long
    [Documentation]    There are too many sleeps to meet deadline.
    ${value_list} =    BuiltIn.Set_Variable    1    1    1
    ${getter} =    Create_Scenario_Getter_Closure    ${value_list}    delay=0s    fail_on_negative=True
    ${date_now} =    DateTime.Get_Current_Date
    ${date_deadline} =    DateTime.Add_Time_To_Date    ${date_now}    1.05
    ${state}    ${status}    ${result} =    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=0.55    count=3
    ...    getter=${getter}    safe_validator=${standard_validator}    initial_state=1
    BuiltIn.Should_Be_Equal    ${state}    1
    BuiltIn.Should_Be_Equal    ${status}    FAIL
    BuiltIn.Should_Be_Equal    ${result}    Not possible to succeed within the deadline. Last result: No result yet.

GASSVHTSCBD_Slow_Getter
    [Documentation]    Getter takes additional time, deadline is encountered.
    ${value_list} =    BuiltIn.Set_Variable    1    1    1
    ${getter} =    Create_Scenario_Getter_Closure    ${value_list}    delay=0.21s    fail_on_negative=True
    ${date_now} =    DateTime.Get_Current_Date
    ${date_deadline} =    DateTime.Add_Time_To_Date    ${date_now}    1.2
    ${state}    ${status}    ${result} =    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=0.4    count=3
    ...    getter=${getter}    safe_validator=${standard_validator}    initial_state=1
    BuiltIn.Should_Be_Equal    ${state}    1
    BuiltIn.Should_Be_Equal    ${status}    FAIL
    BuiltIn.Should_Be_Equal    ${result}    Not possible to succeed within the deadline. Last result: Validated stable: 1

GASSVHTSCBD_Data_Become_Invalid
    [Documentation]    Validator fails at the last try.
    ${value_list} =    BuiltIn.Set_Variable    1    1    2
    ${getter} =    Create_Scenario_Getter_Closure    ${value_list}    delay=0s    fail_on_negative=True
    ${date_now} =    DateTime.Get_Current_Date
    ${date_deadline} =    DateTime.Add_Time_To_Date    ${date_now}    1.35
    ${state}    ${status}    ${result} =    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=0.4    count=3
    ...    getter=${getter}    safe_validator=${standard_validator}    initial_state=1
    BuiltIn.Should_Be_Equal    ${state}    2
    BuiltIn.Should_Be_Equal    ${status}    FAIL
    BuiltIn.Should_Be_Equal    ${result}    Validator failed: Data value has changed.

GASSVHTSCBD_Getter_Error
    [Documentation]    Getter fails at the last try.
    ${value_list} =    BuiltIn.Set_Variable    1    1    -1
    ${getter} =    Create_Scenario_Getter_Closure    ${value_list}    delay=0s    fail_on_negative=True
    ${date_now} =    DateTime.Get_Current_Date
    ${date_deadline} =    DateTime.Add_Time_To_Date    ${date_now}    1.35
    ${state}    ${status}    ${result} =    Getter_And_Safe_Stateful_Validator_Have_To_Succeed_Consecutively_By_Deadline    date_deadline=${date_deadline}    period_in_seconds=0.4    count=3
    ...    getter=${getter}    safe_validator=${standard_validator}    initial_state=1
    BuiltIn.Should_Be_Equal    ${state}    1
    BuiltIn.Should_Be_Equal    ${status}    FAIL
    BuiltIn.Should_Be_Equal    ${result}    Getter failed: Got negative -1

WFGASSVCS_Happy
    [Documentation]    Use failing getter and standard validator to show stability scenario passes.
    ${getter} =    Create_Scenario_Getter_Closure    ${stability_scenario}    delay=0s    fail_on_negative=True
    # Validator fails on first data value change, so count=1 means 2 consecutive values.
    # No initial state given to show None is safe state.
    # Robot code itself takes some time, so timeout has to have a reserve.
    ${result} =    Wait_For_Getter_And_Safe_Stateful_Validator_Consecutive_Success    timeout=1.8s    period=0.1s    count=1    getter=${getter}    safe_validator=${standard_validator}
    BuiltIn.Should_Be_Equal    ${result}    Validated stable: 2

WFGEOSSVCS_Happy
    [Documentation]    Use non-failing getter and standard validator to show stability scenario passes.
    ${getter} =    Create_Scenario_Getter_Closure    ${stability_scenario}    delay=0s    fail_on_negative=False
    # Validator fails on first data value change, so count=1 means 2 consecutive values.
    # No initial state given to show None is safe state.
    # Robot code itself takes some time, so timeout has to have a reserve.
    ${result} =    Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success    timeout=1.8s    period=0.1s    count=1    getter=${getter}    safe_validator=${standard_validator}
    BuiltIn.Should_Be_Equal    ${result}    Validated stable: 2

WFGEOSSVCS_Early_exit
    [Documentation]    Use failing getter (and standard validator) to show stability scenario fails quickly.
    ${getter} =    Create_Scenario_Getter_Closure    ${stability_scenario}    delay=0s    fail_on_negative=True
    # Validator fails on first data value change, so count=1 means 2 consecutive values.
    # No initial state given to show None is safe state.
    # Robot code itself takes some time, so timeout has to have a reserve.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success    timeout=1.8s    period=0.1s    count=1
    ...    getter=${getter}    safe_validator=${standard_validator}
    BuiltIn.Should_Be_Equal    ${status}    FAIL
    BuiltIn.Should_Be_Equal    ${message}    Getter failed: Got negative -1

*** Keywords ***
WUT_Setup
    [Documentation]    Call Setup keywords of libraries, define reusable variables.
    WaitUtils.WU_Setup    # includes ScalarClosures.SC_Setup
    ${countdown} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Stateful_Countdown    0
    BuiltIn.Set_Suite_Variable    ${countdown_quick}    ${countdown}
    ${countdown} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Stateful_Countdown    0    delay=0.3s
    BuiltIn.Set_Suite_Variable    ${countdown_slow}    ${countdown}
    ${lsssv} =    ScalarClosures.Closure_From_Keyword_And_Arguments    WaitUtils.Limiting_Stability_Safe_Stateful_Validator_As_Keyword    state_holder    data_holder    valid_minimum=1
    BuiltIn.Set_Suite_Variable    ${standard_validator}    ${lsssv}

Stateful_Countdown
    [Arguments]    ${how_many_before_fail}    ${delay}=0s
    [Documentation]    Simple stateful keyword, counting down successes.
    BuiltIn.Sleep    ${delay}
    BuiltIn.Run_Keyword_If    ${how_many_before_fail} < 1    BuiltIn.Fail    Count is down.
    ${new_count} =    BuiltIn.Evaluate    ${how_many_before_fail} - 1
    [Return]    ${new_count}    still_alive

Scenario_Getter_As_Keyword
    [Arguments]    ${delay}=0s    ${fail_on_negative}=False
    [Documentation]    Keyword to make getter closure from. Relies on suite variable to track private state.
    BuiltIn.Sleep    ${delay}
    ${next_value} =    Collections.Remove_From_List    ${suite_scenario}    0
    BuiltIn.Return_From_Keyword_If    not ${fail_on_negative} or ${next_value} >= 0    ${next_value}
    BuiltIn.Fail    Got negative ${next_value}

Create_Scenario_Getter_Closure
    [Arguments]    ${value_list_as_scalar}    ${delay}=0s    ${fail_on_negative}=False
    [Documentation]    Store values list to suite variable, return getter closure with given kwargs.
    # TODO: Figure out why solution with the list given as varargs does not really work.
    BuiltIn.Set_Suite_Variable    @{suite_scenario}    @{value_list_as_scalar}
    # Sentinel is there to postpone "Expected list-like value, got string." failure when setting @{other_values}.
    ${getter} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Scenario_Getter_As_Keyword    delay=${delay}    fail_on_negative=${fail_on_negative}
    [Return]    ${getter}

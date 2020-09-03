*** Settings ***
Documentation     Robot keyword library (Resource) for supporting functional programming via "scalar closures".
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Python has fist-class functions. It is possible to perform partial application
...               and have the resulting anonymous function passed around as an object.
...               Robot Framework has second class Keywords. Keyword has to be specified by its name,
...               and ordering between positional and named arguments limit their usage.
...
...               There are several different ways how to overcame these limitations
...               to offer something resembling functional programming in Robot.
...               This library does everything via "scalar closures".
...
...               Closure is a function together with values for some seemingly free variables.
...               This library encodes closure as a scalar value (that is in fact a list).
...               Scalars cannot be run in Robot directly, so a method to run them as closure is provided.
...               Instead of alowing arguments, methods to run with substituted values are used.
...               For substitution to work, the original closure has to be defined with (placeholder) arguments.
...               TODO: Look once again for a way to remove this limitation.
...
...               For Keywords of this library to be easily wrappable (and runable with substitution),
...               their arguments are usually positional.
...               TODO: Look once again if adding/substituting named arguments is doable.
...
...               Current limitation: Keywords inside closures may detect there were given @{args} list, even if it is empty.
...
...               There are convenience closures defined, but SC_Setup has to be called to make them available.
Library           Collections

*** Keywords ***
Closure_From_Keyword_And_Arguments
    [Arguments]    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Turn keyword with given arguments into a scalar closure.
    ...
    ...    Implemented as triple of keyword name, args as scalar and kwargs as scalar.
    [Return]    ${keyword}    ${args}    ${kwargs}

Run_Closure_As_Is
    [Arguments]    ${closure}
    [Documentation]    Run the keyword from closure without affecting arguments.
    ${keyword}    ${args}    ${kwargs} =    BuiltIn.Set_Variable    ${closure}
    ${result} =    BuiltIn.Run_Keyword    ${keyword}    @{args}    &{kwargs}
    [Return]    ${result}

Run_Closure_After_Replacing_First_Argument
    [Arguments]    ${closure}    ${argument}
    [Documentation]    Run the keyword from closure with replaced first positional argument.
    ...
    ...    Note, this will currently fail if the closure was created with less than 1 positional argument.
    ${keyword}    ${args}    ${kwargs} =    BuiltIn.Set_Variable    ${closure}
    Collections.Set_List_Value    ${args}    0    ${argument}
    # TODO: Catch failure and use Collections.Append_To_List to overcome current limitation.
    ${result} =    BuiltIn.Run_Keyword    ${keyword}    @{args}    &{kwargs}
    [Return]    ${result}

Run_Closure_After_Replacing_First_Two_Arguments
    [Arguments]    ${closure}    ${arg1}    ${arg2}
    [Documentation]    Run the keyword from closure with replaced first two positional arguments.
    ...
    ...    Note, this will currently fail if the closure was created with less than 2 positional arguments.
    ${keyword}    ${args}    ${kwargs} =    BuiltIn.Set_Variable    ${closure}
    Collections.Set_List_Value    ${args}    0    ${arg1}
    Collections.Set_List_Value    ${args}    1    ${arg2}
    ${result} =    BuiltIn.Run_Keyword    ${keyword}    @{args}    &{kwargs}
    [Return]    ${result}

Run_Keyword_And_Collect_Garbage
    [Arguments]    ${keyword_to_gc}=BuiltIn.Fail    @{args}    &{kwargs}
    [Documentation]    Runs Keyword, but performs garbage collection before pass/fail.
    ...
    ...    TODO: Move to more appropriate Resource.
    ...
    ...    Keyword to run is given as named argument, hopefully to not mess with replaced arg execution.
    ...    TODO: Test that, as the "hopefully" part may not really work.
    ...
    ...    Return value / failure message is copied from Keyword response.
    ...
    ...    This is a convenience wrapper to be used by callers.
    ...    Usually, Run_Closure_* end up being wrapped this way.
    ...
    ...    Some Keywords may generate a LOT of garbage, especially when
    ...    they download massive datasets and then passage them all the way down
    ...    to just one integer or something similarly small (an example can be
    ...    getting count of routes in topology which can generate several tens of
    ...    MB of garbage if the topology contains several million routes). This
    ...    garbage is not immediately reclaimed by Python once it is no longer in
    ...    use because Robot creates cycled structures that hold references to
    ...    this multi-megabyte garbage. Allowing this garbage to build could cause
    ...    "sudden death syndrome" (OOM killer invocation) of the Robot process
    ...    before Python decides to collect the multi-megabyte pieces of the
    ...    garbage on its own.
    # Execute Keyword but postpone failing.
    ${status}    ${message}=    BuiltIn.Run Keyword And Ignore Error    ${keyword_to_gc}    @{args}    &{kwargs}
    # Collect garbage.
    BuiltIn.Evaluate    gc.collect()    modules=gc
    # Resume possible failure state
    Propagate_Fail    status=${status}    message=${message}
    # So we have passed, return value.
    [Return]    ${message}

Propagate_Fail
    [Arguments]    ${status}=PASS    ${message}=Message unknown.
    [Documentation]    If ${status} is PASS do nothing. Otherwise Fail with ${message}.
    ...
    ...    TODO: Move to more appropriate Resource.
    BuiltIn.Return_From_Keyword_If    '''${status}''' == '''PASS'''
    BuiltIn.Fail    ${message}

SC_Setup
    [Documentation]    Resource setup. Create closures and assign them to suite variables.
    ...
    ...    As scalar closures are values (as opposed to Keywords), lowercase is used.
    ...    Prefix of Resource name and two underscores is added to avoid possible name clashes with other libraries.
    # No need to detect multiple Setup calls.
    ${sc_fail} =    Closure_From_Keyword_And_Arguments    BuiltIn.Fail
    BuiltIn.Set_Suite_Variable    ${ScalarClosures__fail}    ${sc_fail}
    ${sc_identity} =    Closure_From_Keyword_And_Arguments    BuiltIn.Set_Variable    placeholder
    BuiltIn.Set_Suite_Variable    ${ScalarClosures__identity}    ${sc_identity}

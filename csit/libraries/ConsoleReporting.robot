*** Settings ***
Documentation     Pretty-print reports on the console
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Implements a console reporting facility to allow tests to report their
...               progress on the console. The resulting reports are designed to blend
...               nicely into the Robot console output. This enhances test debuggability
...               by allowing the test to emit critical progress data onto the console
...               where they are available for immediate consumption and even when Robot
...               crashes, preventing it from producing its usual logs.
...
...               The facility is disabled by default but can be enabled by putting
...               "-v VERBOSE_RUN:True" on the Robot command line.
...
...               TODO: The "--console type" command line argument can be used to change
...               how robot reports the test results on console. Currently the user
...               must take care to not use "-v VERBOSE_RUN:True" with "--console"
...               type other than "verbose". Implement detection of the console
...               type and disable this logging if it is not "verbose".

*** Variables ***
${VERBOSE_RUN}    False

*** Keywords ***
ConsoleReporting__Delimiter
    ${line}=    BuiltIn.Evaluate    '-- '*23+'-+'+' '*6+'|'
    BuiltIn.Log_To_Console    ${line}

Start_Verbose_Test
    [Documentation]    Put this into the test setup of any test that uses the verbose reporting facility.
    ...    Prints a delimiter and positions the cursor on the start of the next line.
    ...    This makes the console ready for "Report_To_Console" which outputs the lines
    ...    without breaking the pretty formatting of the Robot suite. Does nothing if the
    ...    verbose console logging is not enabled.
    Return_From_Keyword_If    not ${VERBOSE_RUN}
    ${line}=    BuiltIn.Evaluate    ' '*6
    BuiltIn.Log_To_Console    \x08\x08${SPACE}${SPACE}|${line}|
    ConsoleReporting__Delimiter

Report_To_Console
    [Arguments]    ${text}
    [Documentation]    Emit the line into the verbose console log.
    ...    Formats the given line to make it blend nicely into the Robot's verbose output.
    ...    Does nothing if the verbose console logging is not enabled.
    Return_From_Keyword_If    not ${VERBOSE_RUN}
    ${length}=    BuiltIn.Evaluate    70-len('${text}')
    ${line}=    BuiltIn.Evaluate    ' '*${length}
    ${small}=    BuiltIn.Evaluate    ' '*6
    BuiltIn.Log_To_Console    ${text}${line}|${small}|

End_Verbose_Test
    [Documentation]    Put this into the test teardown of any test that uses the verbose reporting facility.
    ...    Emits a delimiter and places the cursor in a position that causes
    ...    the final test result to blend nicely into the output.
    ...    Does nothing if the verbose console logging is not enabled.
    Return_From_Keyword_If    not ${VERBOSE_RUN}
    ConsoleReporting__Delimiter
    ${line}=    BuiltIn.Evaluate    ' '*70
    BuiltIn.Log_To_Console    ${line}    no_newline=True

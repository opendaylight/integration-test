*** Settings ***
Documentation     Resource for handling situations when running on system with low entropy.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Establishing a SSH connection needs a source of cryptographically strong
...               (pseudo)random numbers. Linux can gather entropy by measuring duration
...               of various operations, but a freshly started Robot VM does not have
...               long enough history for the amount of entropy needed for new SSH connection.
...               That can lead to unpredictable failures in test suites.
...
...               This Resource contains keywords to detect and alleviate such situations.
...
...               Ideally, this would be tied with SSH session creation.
...               But SSHLibrary only starts to create the actual connection on Login,
...               and we have "Open+Login" keywords scattered around various Resources.
...               For now, this is just a simple standalone check to be included anywhere needed.
...
...               TODO: If there is a central "Open+Login" keyword everyone uses (e.g. in SSHKeywords),
...               thi can be inlined, or otherwise refactored.
Library           OperatingSystem

*** Variables ***
${ROBOT_RUNS_ON_LINUX}    True    # TODO: Autodetect?

*** Keywords ***
Check_Entropy
    [Arguments]    ${needed}=1000
    [Documentation]    Get actual entropy, fail if it is below ${needed}.
    BuiltIn.Return_From_Keyword_If    not (${ROBOT_RUNS_ON_LINUX})
    ${actual} =    OperatingSystem.Run    cat /proc/sys/kernel/random/entropy_avail
    # Conversions before comparison, to prevent unexpected strings get interpreted as Python code.
    ${needed_int} =    BuiltIn.Convert_To_Integer    ${needed}    base=10
    ${actual_int} =    BuiltIn.Convert_To_Integer    ${actual}    base=10
    BuiltIn.Should_Be_True    ${needed_int} <= ${actual_int}    Not enough entropy. needed: ${needed_int}; actual: ${actual_int}
    # TODO: We could return ${actual_int} here. Would users ever use it?

Wait_For_Entropy
    [Arguments]    ${timeout}=60s    ${refresh}=1s    ${needed}=1000
    [Documetation]    Repeatedly check entropy. If at lest ${needed}, pass. If longer than ${timeout}, fail.
    BuiltIn.Return_From_Keyword_If    not (${ROBOT_RUNS_ON_LINUX})
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Check_Entropy    ${needed}
    # TODO: Return actual?

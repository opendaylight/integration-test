*** Settings ***
Documentation     Resource for keywords specializing on detection of Bugs related to Controller project.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               We already have SetpUtils.Teardown_Test_Show_Bugs_If_Test_Failed
...               which can be used to map test case fail to list of Bugs.
...               We also have SetupUtils.Set_Known_Bug_Id which can be used to map
...               a failure in a part of testcase execution to a single Bug.
...               But that is still not precise enough.
...               We have Bugs which can appear in different test, which require additional code
...               in order to categorize the symptom, and there might be multiple Bugs with the same symptom.
...
...               This Resource hosts specialized code for detecting known Bugs of Controller project.
...               Note that this resource will obsolete quickly if not maintained regularly.
Resource          ${CURDIR}/../SymptomDetection.robot

*** Variables ***
${BUG_8619_SUBSTRING}    ReadTimeout    # RequestsLibrary might change its output in future.

*** Keywords ***
Check_8420
    [Arguments]    ${expected_constant}    ${actual_constant}
    [Documentation]    Fail if the two values do not match.
    BuiltIn.Should_Be_Equal    ${expected_constant}    ${actual_constant}    Unexpected constant, Bug 8420 is present.

Check_8494
    [Arguments]    ${response}
    [Documentation]    Fail if "None" is a substring of \${response} string representation.
    SymptomDetection.Fail_On_Direct_Substring    ${response}    None    Bug 8494 is present

Check_8619
    [Arguments]    ${response}
    [Documentation]    Fail if "ReadTimeout" is a substring of \${response} string representation.
    SymptomDetection.Fail_On_Direct_Substring    ${response}    ${BUG_8619_SUBSTRING}    Bug 8619 is present

Check_8733
    [Arguments]    ${copy_matches}
    [Documentation]    Fail if \${copy_matches} is not true.
    BuiltIn.Should_Be_True    ${copy_matches}    Data does not match, Bug 8733 is present.

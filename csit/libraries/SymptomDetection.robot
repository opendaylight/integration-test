*** Settings ***
Documentation     Resource with keywords useful for checking objects for Bug symptoms.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               While every project or component is encouraged to maintain a specific resource
...               for Bug symptoms possibly appearing in their observed data,
...               some keywords are expected to be common across multiple projects.
...               Such keywords should be placed here.
...
...               TODO: Add high-level keyword summary.

*** Variables ***
# TODO: Perhaps http code lists from TemplatedRequests can be here? Perhaps new HttpCodes resource.

*** Keywords ***
Fail_On_Direct_Substring
    [Arguments]    ${object}    ${substring}    ${message}=Caller has not specified why this is wrong
    [Documentation]    Convert \${object} to string, fail if \${substring} is found.
    ...    Fail message is constructed with help of \${message}.
    ...    The string representation is returned to allow further processing.
    ${string} =    BuiltIn.Convert_To_String    ${object}
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Contain    ${string}    ${substring}
    BuiltIn.Return_From_Keyword_If    "${status}" != "PASS"    ${string}
    BuiltIn.Fail    ${substring} found. ${message}: ${string}

# TODO: Fail_On_Multiple_Substrings? Fail_On_Regexp?

Fail_On_Missing_Attribute
    [Arguments]    ${object}    ${attribute}    ${message}=Caller has not specified why this is wrong
    [Documentation]    Fail if accessing \${attribute} on \${object} leads to error.
    ...    Fail message is constructed with help of \${message}.
    ...    The accessed attribute value is returned to allow futher processing.
    ${status}    ${value} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Set_Variable    ${object.${attribute}}
    BuiltIn.Return_From_Keyword_If    "${status}" == "PASS"    ${value}
    ${string} =    BuiltIn.Convert_To_String    ${object}
    BuiltIn.Fail    Attribute ${attribute} not present. ${message}: ${string}

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
...               TODO: Write high-level summary of keywords present here.

*** Variables ***
# TODO: Perhaps http code lists from TemplatedRequests can be here? Perhaps new HttpCodes resource.

*** Keywords ***
Fail_On_Single_Substring
    [Arguments]    ${object}    ${substring}    ${message}=Caller has not specified why this is wrong
    [Documentation]    
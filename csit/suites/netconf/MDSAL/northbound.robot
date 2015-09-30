*** Settings ***
Documentation     Metconf MDSAL Northbound test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${netconf_prompt}    ]]>]]>
${datadir}        ${CURDIR}/../variables/netconf/MDSAL

*** Test Cases ***
Connect_To_ODL_Netconf
    SSHLibrary.Open_Connection    ${CONTROLLER}    port=${ODL_NETCONF_PORT}    prompt=${netconf_prompt}
    SSHLibrary.Login    ${ODL_NETCONF_USER}    ${ODL_NETCONF_PASSWORD}
    ${hello_message}=    OperatingSystem.Get_File    ${datadir}${/}config.uri
    SSHLibrary.Write    ${hello_message}
    SSHLibrary.Write    ${netconf_prompt}
    SSHLibrary.Read_Until_Prompt

*** Keywords ***
Setup_Everything
    [Documentation]    Setup requests library.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Teardown_Everything
    [Documentation]    Destroy all sessions in the requests library.

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
Library           RequestsLibrary
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${netconf_prompt}    ]]>]]>
${datadir}        ${CURDIR}/../../../variables/netconf/MDSAL
${dataext}        msg
${CONTROLLER_PROMPT}    ${DEFAULT_LINUX_PROMPT}

*** Test Cases ***
Connect_To_ODL_Netconf
    Open_ODL_Netconf_Connection
    ${hello_message}=    Get_Data    hello
    Transmit_Message    ${hello_message}

Get_Config_Running
    Perform_Test    get-config

Missing_Message_ID_Attribute
    Perform_Test    missing-attr

Edit_Config_Modules_Merge
    Perform_Test    config-modules-merge-1

Get_Config_Running_To_Confirm_No_Edit_Before_Commit
    Perform_Test    get-config-no-edit-before-commit

Commit_Edit
    Perform_Test    commit-edit

name0_In_Config_Running_To_Confirm_Edit_After_Commit
    ${reply}=    Load_And_Send_Message    get-config-edit-after-commit
    Check_Expected_String_Present    ${reply}    <name>name0</name>

name0_In_Config_Modules_Via_Restconf
    ${data}=    Utils.Get_Data_From_URI    config    config:modules    headers=${ACCEPT_XML}
    BuiltIn.Should_Contain    ${data}    <name>name0</name>

Edit_Config_Modules_Create_Shall_Fail_Now
    Perform_Test    config-modules-create

Delete_Modules
    Perform_Test    config-modules-delete

Get_Config_Running_To_Confirm_No_Delete_Before_Commit
    ${reply}=    Load_And_Send_Message    get-config-no-delete-before-commit
    Check_Expected_String_Present    ${reply}    <name>name0</name>

Commit_Delete
    Perform_Test    commit-delete

Get_Config_Running_To_Confirm_Delete_After_Commit
    Perform_Test    get-config-delete-after-commit

Restconf_Get_Modules_Shall_Return_404
    ${response}=    RequestsLibrary.Get    config    config:modules    ${ACCEPT_XML}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    404

Commit_No_Transaction
    ${reply}=    Load_And_Send_Message    commit-no-transaction
    ${expected}=    Load_Expected_Reply    commit-no-transaction
    Check_Expected_String_Present    ${reply}    ${expected}

Lock_Candidate
    Perform_Test    candidate-lock

Unlock_Candidate
    Perform_Test    candidate-unlock

Edit_Config_Another_Modules_Merge
    Perform_Test    config-modules-merge-2

Get_Config_Candidate
    ${reply}=    Load_And_Send_Message    get-config-candidate
    Check_Expected_String_Present    ${reply}    <name>name1</name>
    Check_Unexpected_String_Not_Present    ${reply}    name0

Discard_Changes
    Perform_Test    commit-discard

Get_Config_Candidate_To_Confirm_Discard
    Perform_Test    get-config-candidate-discard

Edit_Config_Modules_Multiple_Modules_Merge_1
    Perform_Test    merge-multiple-1

Edit_Config_Modules_Multiple_Modules_Merge_2
    Perform_Test    merge-multiple-2

Edit_Config_Modules_Multiple_Modules_Merge_3
    Perform_Test    merge-multiple-3

Commit_Multiple_Modules_Merge
    Perform_Test    merge-multiple-commit

name2_name3_name4_In_Running_Config
    ${reply}=    Load_And_Send_Message    merge-multiple-check
    Check_Expected_String_Present    ${reply}    <name>name2</name>
    Check_Expected_String_Present    ${reply}    <name>name3</name>
    Check_Expected_String_Present    ${reply}    <name>name4</name>

name2_name3_name4_In_Config_Modules_Via_Restconf
    ${data}=    Utils.Get_Data_From_URI    config    config:modules    headers=${ACCEPT_XML}
    BuiltIn.Should_Contain    ${data}    <name>name2</name>
    BuiltIn.Should_Contain    ${data}    <name>name3</name>
    BuiltIn.Should_Contain    ${data}    <name>name4</name>

Edit_Multiple_Modules_Merge
    Perform_Test    merge-multiple-edit

Commit_Multiple_Modules_Merge_Edit
    Perform_Test    merge-multiple-edit-commit

Check_Multiple_Modules_Merge_Edit
    ${reply}=    Load_And_Send_Message    merge-multiple-edit-check
    Check_Expected_String_Present    ${reply}    <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">2022</port>

Update_Multiple_Modules_Merge
    Perform_Test    merge-multiple-update

Commit_Multiple_Modules_Merge_Update
    Perform_Test    merge-multiple-update-commit

Check_Multiple_Modules_Merge_Update
    ${reply}=    Load_And_Send_Message    merge-multiple-update-check
    Check_Expected_String_Present    ${reply}    <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">3000</port>

Replace_Multiple_Modules_Merge
    Perform_Test    merge-multiple-replace

Commit_Multiple_Modules_Merge_Replace
    Perform_Test    merge-multiple-replace-commit

Check_Multiple_Modules_Merge_Replace
    ${reply}=    Load_And_Send_Message    merge-multiple-replace-check
    Check_Expected_String_Present    ${reply}    <name>vpp</name>
    Check_Expected_String_Present    ${reply}    <address xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">10.194.132.42</address>
    Check_Expected_String_Present    ${reply}    <tcp-only xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">false</tcp-only>
    Check_Expected_String_Present    ${reply}    <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">4000</port>
    Check_Expected_String_Present    ${reply}    <password xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">admin</password>
    Check_Expected_String_Present    ${reply}    <username xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">admin</username>
    Check_Unexpected_String_Not_Present    ${reply}    <name>global-event-executor</name>
    Check_Unexpected_String_Not_Present    ${reply}    <name>binding-osgi-broker</name>
    Check_Unexpected_String_Not_Present    ${reply}    <name>dom-broker</name>
    Check_Unexpected_String_Not_Present    ${reply}    <name>global-netconf-dispatcher</name>
    Check_Unexpected_String_Not_Present    ${reply}    <name>global-netconf-processing-executor</name>

Remove_Multiple_Modules
    Perform_Test    merge-multiple-remove

Commit_Multiple_Modules_Removal
    Perform_Test    merge-multiple-remove-commit

Delete_Not_Existing_Module
    Perform_Test    delete-not-existing

Commit_Delete_Not_Existing_Module
    Perform_Test    delete-not-existing-commit

Remove_Not_Existing_Module
    Perform_Test    remove-not-existing

Commit_Remove_Not_Existing_Module
    Perform_Test    remove-not-existing-commit

Close_Session
    Perform_Test    close-session

*** Keywords ***
Get_Data
    [Arguments]    ${name}
    [Documentation]    Load the specified data from the data directory and return it.
    ${data}=    OperatingSystem.Get_File    ${datadir}${/}${name}.${dataext}
    [Return]    ${data}

Open_ODL_Netconf_Connection
    [Arguments]    ${host}=${CONTROLLER}    ${port}=${ODL_NETCONF_PORT}    ${user}=${ODL_NETCONF_USER}    ${password}=${ODL_NETCONF_PASSWORD}
    [Documentation]    Open a netconf connecion to the given machine.
    SSHLibrary.Open_Connection    ${host}    prompt=${CONTROLLER_PROMPT}    timeout=10s
    Utils.Flexible_Controller_Login
    SSHLibrary.Write    sshpass -p ${password} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${user}\@127.0.0.1 -p ${port} -s netconf
    ${hello}=    SSHLibrary.Read_Until    ${netconf_prompt}
    [Return]    ${hello}

Transmit_Message
    [Arguments]    ${message}
    [Documentation]    Transmit message to Netconf connection and discard the echo of the message.
    SSHLibrary.Write    ${message}
    SSHLibrary.Write    ${netconf_prompt}
    SSHLibrary.Read_Until    ${netconf_prompt}

Send_Message
    [Arguments]    ${message}
    [Documentation]    Send message to Netconf connection and get the reply.
    Transmit_Message    ${message}
    ${reply}=    SSHLibrary.Read_Until    ${netconf_prompt}
    [Return]    ${reply}

Prepare_For_Search
    [Arguments]    ${searched_string}
    ${result}=    BuiltIn.Evaluate    "\\r\\n"+"\\r\\n".join("""${searched_string}""".split("\\n"))
    [Return]    ${result}

Check_Reply_Exactly_As_Expected
    [Arguments]    ${reply}    ${expected_reply}
    ${expected}=    Prepare_For_Search    ${expected_reply}
    BuiltIn.Should_Be_Equal    ${reply}    ${expected}${netconf_prompt}

Check_Expected_String_Present
    [Arguments]    ${reply}    ${expected_string}
    ${expected}=    Prepare_For_Search    ${expected_string}
    BuiltIn.Should_Contain    ${reply}    ${expected}

Check_Unexpected_String_Not_Present
    [Arguments]    ${reply}    ${unexpected_string}
    ${unexpected}=    Prepare_For_Search    ${unexpected_string}
    BuiltIn.Should_Not_Contain    ${reply}    ${unexpected}

Load_And_Send_Message
    [Arguments]    ${name}
    ${request}=    Get_Data    ${name}-request
    ${reply}=    Send_Message    ${request}
    [Return]    ${reply}

Load_Expected_Reply
    [Arguments]    ${name}
    ${expected}=    Get_Data    ${name}-reply
    [Return]    ${expected}

Close_ODL_Netconf_Connection
    Utils.Write_Bare_Ctrl_D
    SSHLibrary.Read_Until_Prompt

Setup_Everything
    [Documentation]    Setup requests library.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    config    http://${CONTROLLER}:${RESTCONFPORT}${CONFIG_API}    auth=${AUTH}

Teardown_Everything
    [Documentation]    Destroy all sessions in the requests library.
    Close_ODL_Netconf_Connection
    RequestsLibrary.Delete_All_Sessions

Perform_Test
    [Arguments]    ${name}    ${exact-match}=True
    ${actual}=    Load_And_Send_Message    ${name}
    ${reply}=    Load_Expected_Reply    ${name}
    Check_Reply_Exactly_As_Expected    ${actual}    ${reply}
    [Return]    ${actual}

Check_Not_Present
    [Arguments]    ${actual}    ${name}    ${number}
    ${unexpected}=    Get_Data    ${name}-reply-${number}
    Check_Unexpected_String_Not_Present    ${actual}    ${unexpected}

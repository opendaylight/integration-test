*** Settings ***
Documentation     Metconf MDSAL Northbound test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               The request produced by test cases "Get Config Running", "Get Config Running
...               To Confirm No_Edit Before Commit", "Get Config Running To Confirm Delete
...               After Commit" and "Get Config Candidate To Confirm Discard" all use the same
...               message id ("empty") for their requests. This is possible because the
...               requests produced by this suite are strictly serialized. The RFC 6241 does
...               not state that these IDs are unique, it only requires that each ID used is
...               "XML attribute normalized" if the client wants it to be returned unmodified.
...               The RFC specifically says that "the content of this attribute is not
...               interpreted in any way, it only is stored to be returned with the reply to
...               the request. The reuse of the "empty" string for the 4 test cases was chosen
...               for simplicity.
...
...               TODO: Change the 4 testcases to use unique message IDs.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           RequestsLibrary
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${datadir}        ${CURDIR}/../../../variables/netconf/MDSAL
${dataext}        msg
${ssh_netconf_pid}    -1

*** Test Cases ***
Connect_To_ODL_Netconf
    [Documentation]    Connect to ODL Netconf and fail if that is not possible.
    Open_ODL_Netconf_Connection
    ${hello_message}=    Get_Data    hello
    Transmit_Message    ${hello_message}

Get_Config_Running
    [Documentation]    Make sure the configuration has only the default elements in it.
    ${reply}=    Load_And_Send_Message    get-config
    BuiltIn.Should_Not_Contain    ${reply}    <name>name0</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>name1</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>name2</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>name3</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>name4</name>
    BuiltIn.Set_Suite_Variable    ${empty_config}    ${reply}

Missing_Message_ID_Attribute
    [Documentation]    Check that messages with missing "message-ID" attribute are rejected with the correct error (RFC 6241, section 4.1).
    Perform_Test    missing-attr

Additional_Attributes_In_Message
    [Documentation]    Check that additional attributes in messages are returned properly (RFC 6241, sections 4.1 and 4.2).
    ${reply}=    Load_And_Send_Message    additional-attr
    BuiltIn.Should_Contain    ${reply}    xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"
    BuiltIn.Should_Contain    ${reply}    message-id="1"
    BuiltIn.Should_Contain    ${reply}    attribute="something"
    BuiltIn.Should_Contain    ${reply}    additional="otherthing"
    BuiltIn.Should_Contain    ${reply}    xmlns:prefix="http://www.example.com/my-schema-example.html"

Edit_Config_Modules_Merge
    [Documentation]    Request a "merge" operation adding an element in candidate configuration and check the reply.
    Perform_Test    config-modules-merge-1

Get_Config_Running_To_Confirm_No_Edit_Before_Commit
    [Documentation]    Make sure the running configuration is still unchanged as the change was not commited yet.
    Send_And_Check    get-config-no-edit-before-commit    ${empty_config}

Commit_Edit
    [Documentation]    Commit the change and check the reply.
    Perform_Test    commit-edit

name0_In_Config_Running_To_Confirm_Edit_After_Commit
    [Documentation]    Check that the change is now in the configuration.
    ${reply}=    Load_And_Send_Message    get-config-edit-after-commit
    BuiltIn.Should_Contain    ${reply}    <name>name0</name>

name0_In_Config_Modules_Via_Restconf
    [Documentation]    Check that the change is also visible through Restconf.
    ${data}=    Utils.Get_Data_From_URI    config    config:modules    headers=${ACCEPT_XML}
    BuiltIn.Should_Contain    ${data}    <name>name0</name>

Edit_Config_Modules_Create_Shall_Fail_Now
    [Documentation]    Request a "create" operation of an element that already exists and check that it fails with the correct error (RFC 6241, section 7.2, operation "create").
    Perform_Test    config-modules-create

Delete_Modules
    [Documentation]    Delete the created element from the candidate configuration and check the reply.
    Perform_Test    config-modules-delete

Get_Config_Running_To_Confirm_No_Delete_Before_Commit
    [Documentation]    Make sure the element is still present in the running configuration as the delete command was not committed yet.
    ${reply}=    Load_And_Send_Message    get-config-no-delete-before-commit
    BuiltIn.Should_Contain    ${reply}    <name>name0</name>

Commit_Delete
    [Documentation]    Commit the deletion of the element and check the reply.
    Perform_Test    commit-delete

Get_Config_Running_To_Confirm_Delete_After_Commit
    [Documentation]    Check that the element is gone.
    Send_And_Check    get-config-delete-after-commit    ${empty_config}

Restconf_Get_Modules_Shall_Return_404
    [Documentation]    Check that "Not Found" is returned when Restconf is asked for the deleted element.
    ${response}=    RequestsLibrary.Get    config    config:modules    ${ACCEPT_XML}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    404

Commit_No_Transaction
    [Documentation]    Attempt to perform "commit" when there are no changes in the candidate configuration and check that it fails with the correct error.
    Test_Commit_With_No_Transactions

Edit_Config_Another_Modules_Merge
    [Documentation]    Create the element in the candidate configuration again and check the reply.
    Perform_Test    config-modules-merge-2

Get_Config_Candidate
    [Documentation]    Check that the element is present in the candidate configuration.
    ${reply}=    Load_And_Send_Message    get-config-candidate
    BuiltIn.Should_Contain    ${reply}    <name>name1</name>
    BuiltIn.Should_Not_Contain    ${reply}    name0

Discard_Changes
    [Documentation]    Ask the server to discard the candidate and check the reply.
    Perform_Test    commit-discard

Get_Config_Candidate_To_Confirm_Discard
    [Documentation]    Check that the element was really discarded.
    Send_And_Check    get-config-candidate-discard    ${empty_config}

Edit_Config_Modules_Multiple_Modules_Merge_1
    [Documentation]    Create the element with "name2" subelement again and check the reply.
    Perform_Test    merge-multiple-1

Edit_Config_Modules_Multiple_Modules_Merge_2
    [Documentation]    Add a "name3" subelement to the element and check the reply.
    Perform_Test    merge-multiple-2

Edit_Config_Modules_Multiple_Modules_Merge_3
    [Documentation]    Add a "name4" subelement to the element and check the reply.
    Perform_Test    merge-multiple-3

Commit_Multiple_Modules_Merge
    [Documentation]    Commit the changes and check the reply.
    Perform_Test    merge-multiple-commit

name2_name3_name4_In_Running_Config
    [Documentation]    Check that the 3 subelements are now present in the running configuration.
    ${reply}=    Load_And_Send_Message    merge-multiple-check
    BuiltIn.Should_Contain    ${reply}    <name>name2</name>
    BuiltIn.Should_Contain    ${reply}    <name>name3</name>
    BuiltIn.Should_Contain    ${reply}    <name>name4</name>

name2_name3_name4_In_Config_Modules_Via_Restconf
    [Documentation]    Check that the 3 subelements are visible via Restconf.
    ${data}=    Utils.Get_Data_From_URI    config    config:modules    headers=${ACCEPT_XML}
    BuiltIn.Should_Contain    ${data}    <name>name2</name>
    BuiltIn.Should_Contain    ${data}    <name>name3</name>
    BuiltIn.Should_Contain    ${data}    <name>name4</name>

Edit_Multiple_Modules_Merge
    [Documentation]    Add another subelement named "test" to the element and check the reply.
    Perform_Test    merge-multiple-edit

Commit_Multiple_Modules_Merge_Edit
    [Documentation]    Commit the addition of the "test" subelement and check the reply.
    Perform_Test    merge-multiple-edit-commit

Check_Multiple_Modules_Merge_Edit
    [Documentation]    Check that the "test" subelement exists and has correct value for "port" subelement.
    ${reply}=    Load_And_Send_Message    merge-multiple-edit-check
    BuiltIn.Should_Contain    ${reply}    <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">2022</port>

Update_Multiple_Modules_Merge
    [Documentation]    Update the value of the "port" subelement of the "test" subelement and check the reply.
    Perform_Test    merge-multiple-update

Commit_Multiple_Modules_Merge_Update
    [Documentation]    Commit the update and check the reply.
    Perform_Test    merge-multiple-update-commit

Check_Multiple_Modules_Merge_Update
    [Documentation]    Check that the value of the "port" was really updated.
    ${reply}=    Load_And_Send_Message    merge-multiple-update-check
    BuiltIn.Should_Contain    ${reply}    <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">3000</port>

Replace_Multiple_Modules_Merge
    [Documentation]    Replace the content of the "test" with another completely different and check the reply.
    Perform_Test    merge-multiple-replace

Commit_Multiple_Modules_Merge_Replace
    [Documentation]    Commit the replace and check the reply.
    Perform_Test    merge-multiple-replace-commit

Check_Multiple_Modules_Merge_Replace
    [Documentation]    Check that the new content is there and the old content is gone.
    ${reply}=    Load_And_Send_Message    merge-multiple-replace-check
    BuiltIn.Should_Contain    ${reply}    <name>test</name>
    BuiltIn.Should_Contain    ${reply}    <address xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">10.194.132.42</address>
    BuiltIn.Should_Contain    ${reply}    <tcp-only xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">false</tcp-only>
    BuiltIn.Should_Contain    ${reply}    <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">4000</port>
    BuiltIn.Should_Contain    ${reply}    <password xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">admin</password>
    BuiltIn.Should_Contain    ${reply}    <username xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">admin</username>
    BuiltIn.Should_Not_Contain    ${reply}    <name>global-event-executor</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>binding-osgi-broker</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>dom-broker</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>global-netconf-dispatcher</name>
    BuiltIn.Should_Not_Contain    ${reply}    <name>global-netconf-processing-executor</name>

Remove_Multiple_Modules
    [Documentation]    Remove the testing "module" element and all its subelements and check the reply.
    Perform_Test    merge-multiple-remove

Commit_Multiple_Modules_Removal
    [Documentation]    Commit the removal and check the reply.
    Perform_Test    merge-multiple-remove-commit

Delete_Not_Existing_Module
    [Documentation]    Attempt to delete the "module" element again and check that it fails with the correct error.
    Perform_Test    delete-not-existing

Commit_Delete_Not_Existing_Module
    [Documentation]    Attempt to commit and check the reply.
    Test_Commit_With_No_Transactions
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4455

Remove_Not_Existing_Module
    [Documentation]    Attempt to remove the "module" element again and check that the operation is "silently ignored".
    Perform_Test    remove-not-existing

Commit_Remove_Not_Existing_Module
    [Documentation]    Attempt to commit and check the reply.
    Perform_Test    remove-not-existing-commit

Close_Session
    [Documentation]    Close the session and check that it was closed properly.
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
    # The "-s netconf" flag (see the "SSHLibrary.Write" line below)    is not
    # supported by SSHLibrary, therefore we need to use this elaborate and
    # pretty tricky way to connect to the ODL Netconf port.
    # TODO: Extract into NetconfKeywords as there are other tests that are
    #    going to need to use this operation (Netconf Performance and Scaling
    #    comes to my mind now as one of the things tested is the performance
    #    of the direct netconf connection.
    ${control}=    SSHLibrary.Open_Connection    ${host}    prompt=${ODL_SYSTEM_PROMPT}    timeout=10s
    Utils.Flexible_Controller_Login
    BuiltIn.Set_Suite_Variable    ${ssh_control}    ${control}
    ${netconf}=    SSHLibrary.Open_Connection    ${host}    prompt=${ODL_SYSTEM_PROMPT}    timeout=10s
    Utils.Flexible_Controller_Login
    BuiltIn.Set_Suite_Variable    ${ssh_netconf}    ${netconf}
    SSHLibrary.Write    sshpass -p ${password} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${user}\@127.0.0.1 -p ${port} -s netconf
    ${hello}=    SSHLibrary.Read_Until    ${ODL_NETCONF_PROMPT}
    SSHLibrary.Switch_Connection    ${ssh_control}
    ${pid}=    SSHLibrary.Execute_Command    ps -A | grep sshpass | cut -b 1-6
    BuiltIn.Set_Suite_Variable    ${ssh_netconf_pid}    ${pid}
    SSHLibrary.Switch_Connection    ${ssh_netconf}
    [Return]    ${hello}

Transmit_Message
    [Arguments]    ${message}
    [Documentation]    Transmit message to Netconf connection and discard the echo of the message.
    SSHLibrary.Write    ${message}
    SSHLibrary.Write    ${ODL_NETCONF_PROMPT}
    SSHLibrary.Read_Until    ${ODL_NETCONF_PROMPT}

Send_Message
    [Arguments]    ${message}
    [Documentation]    Send message to Netconf connection and get the reply.
    Transmit_Message    ${message}
    ${reply}=    SSHLibrary.Read_Until    ${ODL_NETCONF_PROMPT}
    [Return]    ${reply}

Prepare_For_Search
    [Arguments]    ${searched_string}
    [Documentation]    Prepare the specified string for searching in Netconf connection replies.
    ...    The string passed to this keyword is coming from a data
    ...    file which has different end of line conventions than
    ...    the actual Netconf reply. This keyword patches the string
    ...    to match what Netconf actually returns.
    ${result}=    BuiltIn.Evaluate    "\\r\\n".join("""${searched_string}""".split("\\n"))
    [Return]    ${result}

Load_And_Send_Message
    [Arguments]    ${name}
    [Documentation]    Load a message from the data file set, send it to Netconf and return the reply.
    ${request}=    Get_Data    ${name}-request
    ${reply}=    Send_Message    ${request}
    [Return]    ${reply}

Load_Expected_Reply
    [Arguments]    ${name}
    [Documentation]    Load the expected reply from the data file set and return it.
    ${expected_reply}=    Get_Data    ${name}-reply
    ${expected}=    Prepare_For_Search    ${expected_reply}
    [Return]    ${expected}

Close_ODL_Netconf_Connection
    [Documentation]    Correctly close the Netconf connection and make sure it is really dead.
    BuiltIn.Return_From_Keyword_If    ${ssh_netconf_pid} == -1
    ${kill_command}=    BuiltIn.Set_Variable    kill ${ssh_netconf_pid}
    BuiltIn.Set_Suite_Variable    ${ssh_netconf_pid}    -1
    SSHLibrary.Switch_Connection    ${ssh_control}
    SSHLibrary.Write    ${kill_command}
    SSHLibrary.Read_Until_Prompt
    SSHLibrary.Switch_Connection    ${ssh_netconf}
    SSHLibrary.Read_Until_Prompt

Setup_Everything
    [Documentation]    Setup resources and create session for Restconf checking.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    config    http://${CONTROLLER}:${RESTCONFPORT}${CONFIG_API}    auth=${AUTH}

Teardown_Everything
    [Documentation]    Close the Netconf connection and destroy all sessions in the requests library.
    Close_ODL_Netconf_Connection
    RequestsLibrary.Delete_All_Sessions

Perform_Test
    [Arguments]    ${name}
    [Documentation]    Load and send the request from the dataset and compare the returned reply to the one stored in the dataset.
    ${actual}=    Load_And_Send_Message    ${name}
    ${expected}=    Load_Expected_Reply    ${name}
    ${newline}=    BuiltIn.Evaluate    "\\r\\n"
    BuiltIn.Should_Be_Equal    ${actual}    ${newline}${expected}${ODL_NETCONF_PROMPT}
    [Return]    ${actual}

Send_And_Check
    [Arguments]    ${name}    ${expected}
    ${actual}=    Load_And_Send_Message    ${name}
    BuiltIn.Should_Be_Equal    ${actual}    ${expected}

Test_Commit_With_No_Transactions
    [Documentation]    Issue a "commit" RPC request and check that it fails with "No current transactions" error.
    ${reply}=    Load_And_Send_Message    commit-no-transaction
    ${expected}=    Load_Expected_Reply    commit-no-transaction
    BuiltIn.Should_Contain    ${reply}    ${expected}

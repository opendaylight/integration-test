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
...
...               TODO: There are many sections with too many "Should_[Not_]Contain" keyword
...               invocations (see Check_Multiple_Modules_Merge_Replace for a particularly bad
...               example). Create a resource that will be able to extract the data from the
...               requests and search for them in the response, then convert to usage of this
...               resource (think "Thou shall not repeat yourself"). The following resource was
...               found when doing research on this:
...               http://robotframework.org/robotframework/latest/libraries/XML.html
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
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
    Create_ODL_Netconf_Connection
    Open_ODL_Netconf_Connection

Get_Config_Running
    [Documentation]    Make sure the configuration has only the default elements in it.
    Check_Test_Objects_Not_Present_In_Config    get-config

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

Send_Stuff_In_Undefined_Namespace
    [Documentation]    Try to send something within an undefined namespace and check the reply complains about the nonexistent namespace and element.
    ${reply}=    Load_And_Send_Message    merge-nonexistent-namespace
    SetupUtils.Set_Known_Bug_Id    5125
    BuiltIn.Should_Not_Contain    ${reply}    java.lang.NullPointerException
    SetupUtils.Set_Unknown_Bug_Id
    BuiltIn.Should_Contain    ${reply}    urn:this:is:in:a:nonexistent:namespace
    BuiltIn.Should_Contain    ${reply}    <rpc-error>

Edit_Config_First_Batch_Merge
    [Documentation]    Request a "merge" operation adding an element in candidate configuration and check the reply.
    Perform_Test    merge-1

Get_Config_Running_To_Confirm_No_Edit_Before_Commit
    [Documentation]    Make sure the running configuration is still unchanged as the change was not commited yet.
    Check_Test_Objects_Not_Present_In_Config    get-config-no-edit-before-commit

Commit_Edit
    [Documentation]    Commit the change and check the reply.
    Perform_Test    commit-edit

First_Batch_In_Config_Running_To_Confirm_Edit_After_Commit
    [Documentation]    Check that the change is now in the configuration.
    ${reply}=    Load_And_Send_Message    get-config-edit-after-commit
    Check_First_Batch_Data_Present    ${reply}

Terminate_Connection_Gracefully
    [Documentation]    Close the session and disconnect.
    Close_ODL_Netconf_Connection_Gracefully

Reconnect_To_ODL_Netconf_After_Graceful_Session_End
    [Documentation]    Reconnect to ODL Netconf and fail if that is not possible.
    Open_ODL_Netconf_Connection

First_Batch_In_Config_Running_After_Reconnect
    [Documentation]    Check that the change is now in the configuration.
    ${reply}=    Load_And_Send_Message    get-config-edit-after-commit
    Check_First_Batch_Data_Present    ${reply}

Edit_Config_Create_Shall_Fail_Now
    [Documentation]    Request a "create" operation of an element that already exists and check that it fails with the correct error (RFC 6241, section 7.2, operation "create").
    Perform_Test    create

Delete_First_Batch
    [Documentation]    Delete the created element from the candidate configuration and check the reply.
    Perform_Test    delete

Get_Config_Running_To_Confirm_No_Delete_Before_Commit
    [Documentation]    Make sure the element is still present in the running configuration as the delete command was not committed yet.
    ${reply}=    Load_And_Send_Message    get-config-no-delete-before-commit
    Check_First_Batch_Data_Present    ${reply}

Commit_Delete
    [Documentation]    Commit the deletion of the element and check the reply.
    Perform_Test    commit-delete

Get_Config_Running_To_Confirm_Delete_After_Commit
    [Documentation]    Check that the element is gone.
    Check_Test_Objects_Not_Present_In_Config    get-config-delete-after-commit

Commit_No_Transaction
    [Documentation]    Attempt to perform "commit" when there are no changes in the candidate configuration and check that it returns OK status.
    Perform_Test    commit-no-transaction
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4455

Edit_Config_Second_Batch_Merge
    [Documentation]    Create an element to be discarded and check the reply.
    Perform_Test    merge-2

Get_And_Check_Config_Candidate_For_Discard
    [Documentation]    Check that the element to be discarded is present in the candidate configuration.
    ${reply}=    Load_And_Send_Message    get-config-candidate
    Check_First_Batch_Data_Not_Present    ${reply}
    Check_Second_Batch_Data_Present    ${reply}

Discard_Changes_Using_Discard_Request
    [Documentation]    Ask the server to discard the candidate and check the reply.
    Perform_Test    commit-discard

Get_And_Check_Config_Candidate_To_Confirm_Discard
    [Documentation]    Check that the element was really discarded.
    Check_Test_Objects_Not_Present_In_Config    get-config-candidate-discard

Edit_Config_Multiple_Batch_Merge_Create
    [Documentation]    Use a create request with the third batch to create the infrastructure.
    Perform_Test    merge-multiple-create

Edit_Config_Multiple_Batch_Merge_Third
    [Documentation]    Use a create request with the third batch to create the infrastructure.
    Perform_Test    merge-multiple-1

Edit_Config_Multiple_Batch_Merge_Fourth
    [Documentation]    Use a merge request with the third batch to create the infrastructure.
    Perform_Test    merge-multiple-2

Edit_Config_Multiple_Batch_Merge_Fifth
    [Documentation]    Add a "name4" subelement to the element and check the reply.
    Perform_Test    merge-multiple-3

Commit_Multiple_Merge
    [Documentation]    Commit the changes and check the reply.
    Perform_Test    merge-multiple-commit

Multiple_Batch_Data_In_Running_Config
    [Documentation]    Check that the 3 subelements are now present in the running configuration.
    ${reply}=    Load_And_Send_Message    merge-multiple-check
    Check_Multiple_Batch_Data_Present    ${reply}

Abort_Connection_To_Simulate_Session_Failure
    [Documentation]    Simulate session failure by disconnecting without terminating the session.
    Abort_ODL_Netconf_Connection

Reconnect_To_ODL_Netconf_After_Session_Failure
    [Documentation]    Reconnect to ODL Netconf and fail if that is not possible.
    Open_ODL_Netconf_Connection

Multiple_Batch_Data_In_Running_Config_After_Session_Failure
    [Documentation]    Check that the 3 subelements are now present in the running configuration.
    ${reply}=    Load_And_Send_Message    merge-multiple-check
    Check_Multiple_Batch_Data_Present    ${reply}

Edit_Multiple_Merge_Data
    [Documentation]    Add another subelement named "test" to the element and check the reply.
    Perform_Test    merge-multiple-edit

Commit_Multiple_Modules_Merge_Edit
    [Documentation]    Commit the addition of the "test" subelement and check the reply.
    Perform_Test    merge-multiple-edit-commit

Check_Multiple_Modules_Merge_Edit
    [Documentation]    Check that the "test" subelement exists and has correct value for "port" subelement.
    ${reply}=    Load_And_Send_Message    merge-multiple-edit-check
    BuiltIn.Should_Contain    ${reply}    <id>test</id>
    BuiltIn.Should_Contain    ${reply}    <model>Dixi</model>
    BuiltIn.Should_Contain    ${reply}    <manufacturer>BMW</manufacturer>
    BuiltIn.Should_Contain    ${reply}    <year>1928</year>

Update_Multiple_Modules_Merge
    [Documentation]    Update the value of the "port" subelement of the "test" subelement and check the reply.
    Perform_Test    merge-multiple-update

Commit_Multiple_Modules_Merge_Update
    [Documentation]    Commit the update and check the reply.
    Perform_Test    merge-multiple-update-commit

Check_Multiple_Modules_Merge_Update
    [Documentation]    Check that the value of the "port" was really updated.
    ${reply}=    Load_And_Send_Message    merge-multiple-update-check
    BuiltIn.Should_Contain    ${reply}    <id>test</id>
    BuiltIn.Should_Contain    ${reply}    <model>Bentley Speed Six</model>
    BuiltIn.Should_Contain    ${reply}    <manufacturer>Bentley</manufacturer>
    BuiltIn.Should_Contain    ${reply}    <year>1930</year>
    BuiltIn.Should_Not_Contain    ${reply}    <model>Dixi</model>
    BuiltIn.Should_Not_Contain    ${reply}    <manufacturer>BMW</manufacturer>
    BuiltIn.Should_Not_Contain    ${reply}    <year>1928</year>

Replace_Multiple_Modules_Merge
    [Documentation]    Replace the content of the "test" with another completely different and check the reply.
    Perform_Test    merge-multiple-replace

Commit_Multiple_Modules_Merge_Replace
    [Documentation]    Commit the replace and check the reply.
    Perform_Test    merge-multiple-replace-commit

Check_Multiple_Modules_Merge_Replace
    [Documentation]    Check that the new content is there and the old content is gone.
    ${reply}=    Load_And_Send_Message    merge-multiple-replace-check
    BuiltIn.Should_Contain    ${reply}    <id>REPLACE</id>
    BuiltIn.Should_Contain    ${reply}    <manufacturer>FIAT</manufacturer>
    BuiltIn.Should_Contain    ${reply}    <model>Panda</model>
    BuiltIn.Should_Contain    ${reply}    <year>2003</year>
    BuiltIn.Should_Contain    ${reply}    <car-id>REPLACE</car-id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>TOY001</id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>CUST001</id>
    BuiltIn.Should_Not_Contain    ${reply}    <car-id>TOY001</car-id>
    BuiltIn.Should_Not_Contain    ${reply}    <person-id>CUST001</person-id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>OLD001</id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>CUST002</id>
    BuiltIn.Should_Not_Contain    ${reply}    <car-id>OLD001</car-id>
    BuiltIn.Should_Not_Contain    ${reply}    <person-id>CUST002</person-id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>CAROLD</id>
    BuiltIn.Should_Contain    ${reply}    <id>CUSTOLD</id>
    BuiltIn.Should_Not_Contain    ${reply}    <car-id>CAROLD</car-id>
    BuiltIn.Should_Not_Contain    ${reply}    <person-id>CUSTOLD</person-id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>CARYOUNG</id>
    BuiltIn.Should_Contain    ${reply}    <id>CUSTYOUNG</id>
    BuiltIn.Should_Not_Contain    ${reply}    <car-id>CARYOUNG</car-id>
    BuiltIn.Should_Contain    ${reply}    <person-id>CUSTYOUNG</person-id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>CARMID</id>
    BuiltIn.Should_Contain    ${reply}    <id>CUSTMID</id>
    BuiltIn.Should_Not_Contain    ${reply}    <car-id>CARMID</car-id>
    BuiltIn.Should_Not_Contain    ${reply}    <person-id>CUSTMID</person-id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>CAROLD2</id>
    BuiltIn.Should_Contain    ${reply}    <id>CUSTOLD2</id>
    BuiltIn.Should_Not_Contain    ${reply}    <car-id>CAROLD2</car-id>
    BuiltIn.Should_Not_Contain    ${reply}    <person-id>CUSTOLD2</person-id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>CUSTBAD</id>
    BuiltIn.Should_Not_Contain    ${reply}    <id>test</id>

Remove_Test_Data
    [Documentation]    Remove the testing elements and all their subelements and check the reply.
    Perform_Test    merge-multiple-remove

Commit_Test_Data_Removal
    [Documentation]    Commit the removal and check the reply.
    Perform_Test    merge-multiple-remove-commit

Delete_Not_Existing_Element
    [Documentation]    Attempt to delete the elements again and check that it fails with the correct error.
    Perform_Test    delete-not-existing

Commit_Delete_Not_Existing_Module
    [Documentation]    Attempt to commit and check the reply.
    Perform_Test    commit-no-transaction
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4455

Remove_Not_Existing_Module
    [Documentation]    Attempt to remove the "module" element again and check that the operation is "silently ignored".
    Perform_Test    remove-not-existing

Commit_Remove_Not_Existing_Module
    [Documentation]    Attempt to commit and check the reply.
    Perform_Test    remove-not-existing-commit
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4455

Close_Session
    [Documentation]    Close the session and check that it was closed properly.
    Perform_Test    close-session

*** Keywords ***
Get_Data
    [Arguments]    ${name}
    [Documentation]    Load the specified data from the data directory and return it.
    ${data}=    OperatingSystem.Get_File    ${datadir}${/}${name}.${dataext}
    [Return]    ${data}

Create_ODL_Netconf_Connection
    [Arguments]    ${host}=${ODL_SYSTEM_IP}    ${port}=${ODL_NETCONF_MDSAL_PORT}    ${user}=${ODL_NETCONF_USER}    ${password}=${ODL_NETCONF_PASSWORD}
    [Documentation]    Open a netconf connecion to the given machine.
    # The "-s netconf" flag (see the "SSHLibrary.Write" line below)    is not
    # supported by SSHLibrary, therefore we need to use this elaborate and
    # pretty tricky way to connect to the ODL Netconf port.
    # TODO: Extract into NetconfKeywords as there are other tests that are
    #    going to need to use this operation (Netconf Performance and Scaling
    #    comes to my mind now as one of the things tested is the performance
    #    of the direct netconf connection.
    # TODO: Make this keyword return a dictionary object with all the
    #    data about the prepared connection neatly packaged. Make all
    #    the other keywords handling the connection accept such an
    #    object and pull the data out of it rather than relying on
    #    global variables. This will allow for tracking more Netconf
    #    connections, increasing utility.
    ${control}=    SSHLibrary.Open_Connection    ${host}    prompt=${ODL_SYSTEM_PROMPT}    timeout=10s
    Utils.Flexible_Controller_Login
    BuiltIn.Set_Suite_Variable    ${ssh_control}    ${control}
    ${netconf}=    SSHLibrary.Open_Connection    ${host}    prompt=${ODL_SYSTEM_PROMPT}    timeout=10s
    Utils.Flexible_Controller_Login
    BuiltIn.Set_Suite_Variable    ${ssh_netconf}    ${netconf}
    BuiltIn.Set_Suite_Variable    ${ssh_port}    ${port}
    BuiltIn.Set_Suite_Variable    ${ssh_user}    ${user}
    BuiltIn.Set_Suite_Variable    ${ssh_password}    ${password}

Reopen_ODL_Netconf_Connection
    [Documentation]    Reopen a closed netconf connection.
    SSHLibrary.Write    sshpass -p ${ssh_password} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user}\@127.0.0.1 -p ${ssh_port} -s netconf
    ${hello}=    SSHLibrary.Read_Until    ${ODL_NETCONF_PROMPT}
    SSHLibrary.Switch_Connection    ${ssh_control}
    ${pid}=    SSHLibrary.Execute_Command    ps -A | grep sshpass | cut -b 1-6
    BuiltIn.Set_Suite_Variable    ${ssh_netconf_pid}    ${pid}
    SSHLibrary.Switch_Connection    ${ssh_netconf}
    [Return]    ${hello}

Open_ODL_Netconf_Connection
    [Documentation]    Open a prepared netconf connecion.
    ${hello}=    Reopen_ODL_Netconf_Connection
    ${hello_message}=    Get_Data    hello
    Transmit_Message    ${hello_message}
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

Abort_ODL_Netconf_Connection
    [Documentation]    Correctly close the Netconf connection and make sure it is really dead.
    BuiltIn.Return_From_Keyword_If    ${ssh_netconf_pid} == -1
    ${kill_command}=    BuiltIn.Set_Variable    kill ${ssh_netconf_pid}
    BuiltIn.Set_Suite_Variable    ${ssh_netconf_pid}    -1
    SSHLibrary.Switch_Connection    ${ssh_control}
    SSHLibrary.Write    ${kill_command}
    SSHLibrary.Read_Until_Prompt
    SSHLibrary.Switch_Connection    ${ssh_netconf}
    SSHLibrary.Read_Until_Prompt

Close_ODL_Netconf_Connection_Gracefully
    Perform_Test    close-session
    Abort_ODL_Netconf_Connection

Setup_Everything
    [Documentation]    Setup resources and create session for Restconf checking.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    config    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${CONFIG_API}    auth=${AUTH}

Teardown_Everything
    [Documentation]    Close the Netconf connection and destroy all sessions in the requests library.
    Abort_ODL_Netconf_Connection
    RequestsLibrary.Delete_All_Sessions

Check_First_Batch_Data
    [Arguments]    ${reply}    ${keyword}
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>TOY001</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CUST001</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <car-id>TOY001</car-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <person-id>CUST001</person-id>

Check_First_Batch_Data_Present
    [Arguments]    ${reply}
    Check_First_Batch_Data    ${reply}    BuiltIn.Should_Contain

Check_First_Batch_Data_Not_Present
    [Arguments]    ${reply}
    Check_First_Batch_Data    ${reply}    BuiltIn.Should_Not_Contain

Check_Second_Batch_Data
    [Arguments]    ${reply}    ${keyword}
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>OLD001</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CUST002</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <car-id>OLD001</car-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <person-id>CUST002</person-id>

Check_Second_Batch_Data_Present
    [Arguments]    ${reply}
    Check_Second_Batch_Data    ${reply}    BuiltIn.Should_Contain

Check_Multiple_Batch_Data
    [Arguments]    ${reply}    ${keyword}
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CAROLD</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CUSTOLD</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <car-id>CAROLD</car-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <person-id>CUSTOLD</person-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CARYOUNG</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CUSTYOUNG</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <car-id>CARYOUNG</car-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <person-id>CUSTYOUNG</person-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CARMID</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CUSTMID</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <car-id>CARMID</car-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <person-id>CUSTMID</person-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CAROLD2</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CUSTOLD2</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <car-id>CAROLD2</car-id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <person-id>CUSTOLD2</person-id>

Check_Multiple_Batch_Data_Absent
    [Arguments]    ${reply}
    Check_Multiple_Batch_Data    ${reply}    BuiltIn.Should_not_Contain

Check_Multiple_Batch_Data_Present
    [Arguments]    ${reply}
    Check_Multiple_Batch_Data    ${reply}    BuiltIn.Should_Contain

Check_Auxiliary_Data
    [Arguments]    ${reply}    ${keyword}
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>CUSTBAD</id>
    BuiltIn.RunKeyword    ${keyword}    ${reply}    <id>test</id>

Check_Test_Objects_Absent
    [Arguments]    ${reply}
    Check_First_Batch_Data_Not_Present    ${reply}
    Check_Second_Batch_Data    ${reply}    BuiltIn.Should_not_Contain
    Check_Multiple_Batch_Data_Absent    ${reply}
    Check_Auxiliary_Data    ${reply}    BuiltIn.Should_not_Contain
    BuiltIn.Should_not_Contain    ${reply}    <id>test</id>

Check_Test_Objects_Not_Present_In_Config
    [Arguments]    ${name}
    [Documentation]    Use dataset with the specified name to get the configuration and check that none of our test objects are there.
    ${reply}=    Load_And_Send_Message    ${name}
    Check_Test_Objects_Absent    ${reply}
    BuiltIn.Should_not_Contain    ${reply}    <id>REPLACE</id>
    [Return]    ${reply}

Perform_Test
    [Arguments]    ${name}
    [Documentation]    Load and send the request from the dataset and compare the returned reply to the one stored in the dataset.
    ${actual}=    Load_And_Send_Message    ${name}
    ${expected}=    Load_Expected_Reply    ${name}
    ${newline}=    BuiltIn.Evaluate    "\\r\\n"
    BuiltIn.Should_Be_Equal    ${newline}${expected}${ODL_NETCONF_PROMPT}    ${actual}
    [Return]    ${actual}

Send_And_Check
    [Arguments]    ${name}    ${expected}
    ${actual}=    Load_And_Send_Message    ${name}
    BuiltIn.Should_Be_Equal    ${expected}    ${actual}

*** Settings ***
Documentation       Karaf library. General utility keywords for interacting with the karaf environment, such as the
...                 karaf console, karaf.log, karaf features, and karaf config files.
...
...                 This library is useful to deal with controller Karaf console for ssh sessions in cluster.
...                 Running Setup_Karaf_Keywords is necessary. If SetupUtils initialization is called, this gets initialized as well.
...                 If this gets initialized, ClusterManagement gets initialized as well.

Library             SSHLibrary
Library             OperatingSystem
Library             ${CURDIR}/netvirt/excepts.py
Resource            ${CURDIR}/ClusterManagement.robot
Resource            ${CURDIR}/SSHKeywords.robot
Variables           ${CURDIR}/../variables/Variables.py


*** Variables ***
${WORKSPACE}                /tmp
${connection_index_dict}    &{EMPTY}


*** Keywords ***
Setup_Karaf_Keywords
    [Documentation]    Initialize ClusterManagement. Open ssh karaf connections to each ODL.
    [Arguments]    ${http_timeout}=${DEFAULT_TIMEOUT_HTTP}
    ClusterManagement.ClusterManagement_Setup    http_timeout=${http_timeout}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ClusterManagement.Run_Bash_Command_On_List_Or_All
    ...    iptables -I INPUT -p tcp --dport ${KARAF_SHELL_PORT} -j ACCEPT; iptables-save
    BuiltIn.Comment    First connections to Karaf console may fail, so WUKS is used. TODO: Track as a Bug.
    FOR    ${index}    IN    @{ClusterManagement__member_index_list}
        BuiltIn.Run_Keyword_And_Ignore_Error
        ...    BuiltIn.Wait_Until_Keyword_Succeeds
        ...    3s
        ...    1s
        ...    Open_Controller_Karaf_Console_On_Background
        ...    member_index=${index}
    END

Verify_Feature_Is_Installed
    [Documentation]    Will Succeed if the given ${feature_name} is found in the output of "feature:list -i"
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Issue_Command_On_Karaf_Console
    ...    feature:list -i | grep ${feature_name}
    ...    ${controller}
    ...    ${karaf_port}
    BuiltIn.Should_Contain    ${output}    ${feature_name}
    RETURN    ${output}

Issue_Command_On_Karaf_Console
    [Documentation]    Will execute the given ${cmd} by ssh'ing to the karaf console running on ${controller}
    ...    Note that this keyword will open&close new SSH connection, without switching back to previously current session.
    [Arguments]    ${cmd}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=10    ${loglevel}=INFO
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    SSHLibrary.Open_Connection
    ...    ${controller}
    ...    port=${karaf_port}
    ...    prompt=${KARAF_PROMPT_LOGIN}
    ...    timeout=${timeout}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    SSHLibrary.Write    ${cmd}
    ${output} =    SSHLibrary.Read_Until_Regexp    ${KARAF_PROMPT}
    SSHLibrary.Write_Bare    logout\n
    SSHLibrary.Close_Connection
    BuiltIn.Log    ${output}
    RETURN    ${output}

Safe_Issue_Command_On_Karaf_Console
    [Documentation]    Run Issue_Command_On_Karaf_Console but restore previous connection afterwards.
    [Arguments]    ${cmd}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=10    ${loglevel}=INFO
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    BuiltIn.Run_Keyword_And_Return
    ...    SSHKeywords.Run_Keyword_Preserve_Connection
    ...    Issue_Command_On_Karaf_Console
    ...    ${cmd}
    ...    ${controller}
    ...    ${karaf_port}
    ...    ${timeout}
    ...    ${loglevel}

Check For Elements On Karaf Command Output Message
    [Documentation]    Will execute the command using Issue Command On Karaf Console then check for the given elements
    ...    in the command output message
    [Arguments]    ${cmd}    ${elements}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Issue_Command_On_Karaf_Console    ${cmd}    ${controller}    ${karaf_port}    ${timeout}
    FOR    ${i}    IN    @{elements}
        BuiltIn.Should_Contain    ${output}    ${i}
    END

Verify_Bundle_Is_Installed
    [Documentation]    Will succeed if the given ${bundle name} is present in the output of "bundle:list -s "
    [Arguments]    ${bundle_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Issue_Command_On_Karaf_Console
    ...    bundle:list -s | grep ${bundle_name}
    ...    ${controller}
    ...    ${karaf_port}
    BuiltIn.Should_Contain    ${output}    ${bundle_name}
    RETURN    ${output}

Verify_Bundle_Is_Not_Installed
    [Documentation]    Will succeed if the given ${bundle_name} is NOT found in the output of "bundle:list -s"
    [Arguments]    ${bundle_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Issue_Command_On_Karaf_Console
    ...    bundle:list -i | grep ${bundle_name}
    ...    ${controller}
    ...    ${karaf_port}
    BuiltIn.Should_Not_Contain    ${output}    ${bundle_name}
    RETURN    ${output}

Check_Karaf_Log_Has_Messages
    [Documentation]    Will succeed if the @{messages} are found in \ the output of "log:display"
    [Arguments]    ${filter_string}    @{message_list}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Issue_Command_On_Karaf_Console    log:display | grep ${filter_string}
    FOR    ${message}    IN    @{message_list}
        BuiltIn.Should_Contain    ${output}    ${message}
    END
    RETURN    ${output}

Check_Karaf_Log_Message_Count
    [Documentation]    Verifies that the ${message} exists specified number of times in
    ...    karaf console log or Karaf Log Folder based on the arg ${use_console}.
    [Arguments]    ${message}    ${count}    ${use_console}=False
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    IF    ${use_console} == False
        Check_Karaf_Log_File    ${message}    ${count}
    ELSE
        Check_Karaf_Log_From_Console    ${message}    ${count}
    END

Check_Karaf_Log_From_Console
    [Documentation]    Verifies that the ${message} exists in the Karaf Console log:display and checks
    ...    that it appears ${count} number of times
    [Arguments]    ${message}    ${count}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Issue_Command_On_Karaf_Console    log:display | grep ${message} | wc -l
    ${line} =    Get Line    ${output}    0
    ${stripped} =    Strip String    ${line}
    Should Be Equal As Strings    ${stripped}    ${count}

Check_Karaf_Log_File
    [Documentation]    Verifies that the ${message} exists in the Karaf Log Folder and checks
    ...    that it appears ${count} number of times
    [Arguments]    ${message}    ${count}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Run Command On Controller
    ...    ${ODL_SYSTEM_IP}
    ...    grep -o ${message} ${WORKSPACE}/${BUNDLEFOLDER}/data/log/* | wc -l
    Should Be Equal As Strings    ${output}    ${count}

Install_A_Feature
    [Documentation]    Will Install the given ${feature_name}
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    BuiltIn.Log    ${timeout}
    ${output} =    Issue_Command_On_Karaf_Console
    ...    feature:install ${feature_name}
    ...    ${controller}
    ...    ${karaf_port}
    ...    ${timeout}
    BuiltIn.Log    ${output}
    RETURN    ${output}

Install_A_Feature_Using_Active_Connection
    [Documentation]    Will Install the given ${feature_name} using active connection
    [Arguments]    ${feature_name}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${cmd} =    BuiltIn.Set_Variable    feature:install ${feature_name}
    SSHLibrary.Write    ${cmd}
    ${output} =    SSHLibrary.Read_Until_Regexp    ${KARAF_PROMPT}
    BuiltIn.Log    ${output}
    RETURN    ${output}

Uninstall_A_Feature
    [Documentation]    Will UnInstall the given ${feature_name}
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Issue_Command_On_Karaf_Console
    ...    feature:uninstall ${feature_name}
    ...    ${controller}
    ...    ${karaf_port}
    ...    ${timeout}
    BuiltIn.Log    ${output}
    RETURN    ${output}

Open_Controller_Karaf_Console_On_Background
    [Documentation]    If there is a stored ssh connection index of connection to the controller's karaf console for ${member_index},
    ...    close the previous connection. In any case create a new connection
    ...    to karaf console for ${member_index}, set correct prompt set and login to karaf console.
    ...    Store connection index for ${member_index} and restore the previous active connection.
    [Arguments]    ${member_index}=${1}    ${timeout}=10    ${loglevel}=INFO
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${current_ssh_connection_object} =    SSHLibrary.Get_Connection
    BuiltIn.Log    ${connection_index_dict}
    BuiltIn.Log    ${member_index}
    ${status}    ${old_connection_index} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    Get From Dictionary
    ...    ${connection_index_dict}
    ...    ${member_index}
    IF    '${status}'=='PASS'
        BuiltIn.Run_Keywords
        ...    SSHLibrary.Switch_Connection
        ...    ${old_connection_index}
        ...    AND
        ...    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    SSHLibrary.Write
        ...    logout
        ...    AND
        ...    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    SSHLibrary.Close_Connection
    END
    ${odl_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${member_index}
    SSHLibrary.Open_Connection
    ...    ${odl_ip}
    ...    port=${KARAF_SHELL_PORT}
    ...    prompt=${KARAF_PROMPT_LOGIN}
    ...    timeout=${timeout}
    ${karaf_connection_object} =    SSHLibrary.Get_Connection
    Collections.Set_To_Dictionary    ${connection_index_dict}    ${member_index}    ${karaf_connection_object.index}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    [Teardown]    Run Keyword If    '${IS_KARAF_APPL}' == 'True'    SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${current_ssh_connection_object.index}

Open_Controller_Karaf_Console_With_Timeout
    [Documentation]    Open new connection to karaf console for member index with specified timeout.
    [Arguments]    ${member_index}=${1}    ${timeout}=3s
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    BuiltIn.Log    ${member_index}
    ${odl_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${member_index}
    SSHLibrary.Open_Connection
    ...    ${odl_ip}
    ...    port=${KARAF_SHELL_PORT}
    ...    prompt=${KARAF_PROMPT_LOGIN}
    ...    timeout=${timeout}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}

Configure_Timeout_For_Karaf_Console
    [Documentation]    Configure a different timeout for each Karaf console.
    [Arguments]    ${timeout}    ${member_index_list}=${EMPTY}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    ${current_connection_object} =    SSHLibrary.Get_Connection
    FOR    ${member_index}    IN    @{index_list}    # usually: 1, 2, 3
        ${karaf_connection_index} =    Collections.Get_From_Dictionary    ${connection_index_dict}    ${member_index}
        SSHLibrary.Switch_Connection    ${karaf_connection_index}
        SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    END
    [Teardown]    Run Keyword If    '${IS_KARAF_APPL}' == 'True'    SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${current_connection_object.index}

Execute_Controller_Karaf_Command_On_Background
    [Documentation]    Send command to karaf without affecting current SSH connection. Read, log and return response.
    [Arguments]    ${command}    ${member_index}=${1}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${karaf_connection_index} =    Collections.Get_From_Dictionary    ${connection_index_dict}    ${member_index}
    ${current_connection_index} =    SSHLibrary.Switch_Connection    ${karaf_connection_index}
    ${status_write}    ${message_write} =    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Write    ${command}
    ${status_wait}    ${message_wait} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    SSHLibrary.Read_Until_Regexp
    ...    ${KARAF_PROMPT}
    IF    '${status_write}' != 'PASS'
        BuiltIn.Fail    Failed to send the command: ${command}
    END
    BuiltIn.Log    ${message_wait}
    IF    '${status_wait}' != 'PASS'
        BuiltIn.Fail    Failed to see prompt after sending the command: ${command}
    END
    RETURN    ${message_wait}
    [Teardown]    Run Keyword If    '${IS_KARAF_APPL}' == 'True'    SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${current_connection_index}

Execute_Controller_Karaf_Command_With_Retry_On_Background
    [Documentation]    Attemp to send command to karaf for ${member_index}, if fail then open connection and try again.
    [Arguments]    ${command}    ${member_index}=${1}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    Execute_Controller_Karaf_Command_On_Background
    ...    ${command}
    ...    ${member_index}
    IF    '${status}' == 'PASS'    RETURN    ${message}
    # TODO: Verify this does not leak connections indices.
    Open_Controller_Karaf_Console_On_Background    ${member_index}
    ${message} =    Execute_Controller_Karaf_Command_On_Background    ${command}    ${member_index}
    RETURN    ${message}

Log_Message_To_Controller_Karaf
    [Documentation]    Make sure this resource is initialized. Send a message into the controller's karaf log file on every node listed (or all).
    ...    By default, failure while processing a node is silently ignored, unless ${tolerate_failure} is False.
    [Arguments]    ${message}    ${member_index_list}=${EMPTY}    ${tolerate_failure}=True
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        ${status}    ${output} =    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    Execute_Controller_Karaf_Command_With_Retry_On_Background
        ...    log:log "ROBOT MESSAGE: ${message}"
        ...    member_index=${index}
        IF    not ${tolerate_failure} and "${status}" != "PASS"
            BuiltIn.Fail    ${output}
        END
    END

Log_Test_Suite_Start_To_Controller_Karaf
    [Documentation]    Log suite name to karaf log, useful in suite setup.
    [Arguments]    ${member_index_list}=${EMPTY}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    Log_Message_To_Controller_Karaf    Starting suite ${SUITE_SOURCE}    ${member_index_list}

Log_Testcase_Start_To_Controller_Karaf
    [Documentation]    Log test case name to karaf log, useful in test case setup.
    [Arguments]    ${member_index_list}=${EMPTY}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    Log_Message_To_Controller_Karaf    Starting test ${SUITE_NAME}.${TEST_NAME}    ${member_index_list}

Set_Bgpcep_Log_Levels
    [Documentation]    Assuming OCKCOB was used, set logging level on bgpcep and protocol loggers without affecting current SSH session.
    [Arguments]    ${bgpcep_level}=${DEFAULT_BGPCEP_LOG_LEVEL}    ${protocol_level}=${DEFAULT_PROTOCOL_LOG_LEVEL}    ${member_index_list}=${EMPTY}
    # FIXME: Move to appropriate Resource
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        Execute_Controller_Karaf_Command_On_Background
        ...    log:set ${bgpcep_level} org.opendaylight.bgpcep
        ...    member_index=${index}
        Execute_Controller_Karaf_Command_On_Background
        ...    log:set ${protocol_level} org.opendaylight.protocol
        ...    member_index=${index}
    END

Get Karaf Log Lines From Test Start
    [Documentation]    Scrapes all log messages that match regexp ${type} which fall after a point given by a log message that
    ...    contains ${test_name}. This is useful if your test cases are marking karaf.log with a message indicating when
    ...    that test case has started; such that you can easily pull out any extra log messsages to parse/log/etc in the
    ...    test logic itself. For example, you can grab all ERRORS that occur during your test case.
    [Arguments]    ${ip}    ${test_name}    ${cmd}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${KARAF_LOG}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${output} =    Run Command On Controller    ${ip}    ${cmd}    ${user}    ${password}    ${prompt}
    @{log_lines} =    Split String    ${output}    ${\n}
    RETURN    ${log_lines}

Fail If Exceptions Found During Test
    [Documentation]    Create a failure if an Exception is found in the karaf.log that has not been whitelisted.
    ...    Will work for single controller jobs as well as 3node cluster jobs
    [Arguments]    ${test_name}    ${log_file}=${KARAF_LOG}    ${fail}=False
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    FOR    ${i}    IN RANGE    1    ${NUM_ODL_SYSTEM} + 1
        ${cmd} =    Set Variable    sed '1,/ROBOT MESSAGE: Starting test ${test_name}/d' ${log_file}
        ${output} =    Get Karaf Log Lines From Test Start    ${ODL_SYSTEM_${i}_IP}    ${test_name}    ${cmd}
        ${exlist}    ${matchlist} =    Verify Exceptions    ${output}
        Write Exceptions Map To File    ${SUITE_NAME}.${TEST_NAME}    /tmp/odl${i}_exceptions.txt
        ${listlength} =    BuiltIn.Get Length    ${exlist}
        IF    "${fail}"=="True" and ${listlength} != 0
            Log And Fail Exceptions    ${exlist}    ${listlength}
        ELSE
            Collections.Log List    ${matchlist}
        END
    END

Log And Fail Exceptions
    [Documentation]    Print the list of failed exceptions and fail the test
    [Arguments]    ${exlist}    ${listlength}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    Collections.Log List    ${exlist}
    ${exstr} =    BuiltIn.Catenate    ${exlist}
    BuiltIn.Fail    New exceptions found: ${listlength}\n${exstr}

Get Karaf Log Type From Test Start
    [Documentation]    Scrapes all log messages that match regexp ${type} which fall after a point given by a log message that
    ...    contains ${test_name}. This is useful if your test cases are marking karaf.log with a message indicating when
    ...    that test case has started; such that you can easily pull out any extra log messsages to parse/log/etc in the
    ...    test logic itself. For example, you can grab all ERRORS that occur during your test case.
    [Arguments]    ${ip}    ${test_name}    ${type}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${KARAF_LOG}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${cmd} =    Set Variable    sed '1,/ROBOT MESSAGE: Starting test ${test_name}/d' ${log_file} | grep '${type}'
    ${output} =    Run Command On Controller    ${ip}    ${cmd}    ${user}    ${password}    ${prompt}
    RETURN    ${output}

Get Karaf Log Types From Test Start
    [Documentation]    A wrapper keyword for "Get Karaf Log Type From Test Start" so that we can parse for multiple types
    ...    of log messages. For example, we can grab all messages of type WARN and ERROR
    [Arguments]    ${ip}    ${test_name}    ${types}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${KARAF_LOG}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    FOR    ${type}    IN    @{types}
        Get Karaf Log Type From Test Start    ${ip}    ${test_name}    ${type}    ${user}    ${password}
        ...    ${prompt}    ${log_file}
    END

Get Karaf Log Events From Test Start
    [Documentation]    Wrapper for the wrapper "Get Karaf Log Types From Test Start" so that we can easily loop over
    ...    any number of controllers to analyze karaf.log for ERROR, WARN and Exception log messages
    [Arguments]    ${test_name}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${log_types} =    Create List    ERROR    WARN    Exception
    FOR    ${i}    IN RANGE    1    ${NUM_ODL_SYSTEM} + 1
        Get Karaf Log Types From Test Start    ${ODL_SYSTEM_${i}_IP}    ${test_name}    ${log_types}
    END

Fail If Exceptions Found During Test Deprecated
    [Documentation]    Create a failure if an Exception is found in the karaf.log. Will work for single controller jobs
    ...    as well as 3node cluster jobs
    [Arguments]    ${test_name}    ${exceptions_white_list}=${EMPTY}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    FOR    ${i}    IN RANGE    1    ${NUM_ODL_SYSTEM} + 1
        Verify Exception Logging In Controller    ${ODL_SYSTEM_${i}_IP}    ${test_name}    ${exceptions_white_list}
    END

Verify Exception Logging In Controller
    [Documentation]    Local keyword to make it easier to loop through N controllers to pull Exceptions from the
    ...    karaf.log file and validate with "Check Against White List"
    [Arguments]    ${controller_ip}    ${test_name}    ${exceptions_white_list}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    ${exceptions} =    Get Karaf Log Type From Test Start    ${controller_ip}    ${test_name}    Exception
    @{log_lines} =    Split String    ${exceptions}    ${\n}
    ${num_log_entries} =    Get Length    ${log_lines}
    IF    ${num_log_entries} == ${0}    RETURN    No Exceptions found.
    FOR    ${log_message}    IN    @{log_lines}
        Check Against White List    ${log_message}    ${exceptions_white_list}
    END

Check Against White List
    [Documentation]    As soon as the ${exceptions_line} is found in one of the elements of ${exceptions_white_list}
    ...    this keyword will exit and give a Pass to the caller. If there is no match, this keyword will end up
    ...    marking a failure. In the case that no exceptions are found, the caller could end up passing a single
    ...    empty line as that is what is returned when a grep on karaf.log has no match, so we can safely return
    ...    in that case as well.
    [Arguments]    ${exception_line}    ${exceptions_white_list}
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    IF    "${exception_line}" == ""    RETURN
    FOR    ${exception}    IN    @{exceptions_white_list}
        IF    "${exception}" in "${exception_line}"
            RETURN    Exceptions found, but whitelisted: ${\n}${exception_line}${\n}
        END
    END
    Fail    Exceptions Found: ${\n}${exception_line}${\n}

Wait_For_Karaf_Log
    [Documentation]    Read karaf logs until message appear
    [Arguments]    ${message}    ${timeout}=60    ${member_index}=${1}
    # TODO: refactor this keyword to use the new workflow to account for multiple controllers.    Initial work was done
    # in this patch https://git.opendaylight.org/gerrit/#/c/45596/
    # however, the consumers of this keyword were breaking after that change.    Initial theory is that a previous
    # keyword used before this "Wait For Karaf Log" keyword was closing the karaf console connection, so the
    # "Flexible SSH Login" keyword from the patch above (45596) was failing.
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    BuiltIn.Log    Waiting for '${message}' in karaf log
    SSHLibrary.Open_Connection
    ...    ${ODL_SYSTEM_IP}
    ...    port=${KARAF_SHELL_PORT}
    ...    prompt=${KARAF_PROMPT_LOGIN}
    ...    timeout=${timeout}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    SSHLibrary.Write    log:tail
    SSHLibrary.Read_Until    ${message}
    SSHLibrary.Write    logout
    SSHLibrary.Close_Connection

Restart_Bundle
    [Documentation]    Restarts bundle passed as argument. Note this operation is only for testing and not production environments
    [Arguments]    ${bundle_id}
    # TODO: prepare this for cluster environment and multiple controllers
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    Execute_Controller_Karaf_Command_With_Retry_On_Background    bundle:restart $(bundle:id '${bundle_id}')

Restart_Karaf
    [Documentation]    Restarts Karaf and polls log to detect when Karaf is up and running again
    # TODO: prepare this for cluster environment and multiple controllers
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    Execute_Controller_Karaf_Command_With_Retry_On_Background    log:clear
    Execute_Controller_Karaf_Command_With_Retry_On_Background    shutdown -r -f
    BuiltIn.Run_Keyword_And_Return_Status
    ...    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    240s
    ...    60s
    ...    Wait_For_Karaf_Log
    ...    Shiro environment initialized in

Restart_Jetty
    [Documentation]    Restarts jetty bundle (to reload certificates or key/truststore information)
    IF    '${IS_KARAF_APPL}' == 'False'    RETURN    Not A Karaf App
    Execute_Controller_Karaf_Command_With_Retry_On_Background    log:clear
    Restart_Bundle    OPS4J Pax Web - Jetty
    Wait_For_Karaf_Log    Started jetty-default

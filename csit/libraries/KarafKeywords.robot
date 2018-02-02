*** Settings ***
Documentation     Karaf library. This library is useful to deal with controller Karaf console for ssh sessions in cluster.
...               Running Setup_Karaf_Keywords is necessary. If SetupUtils initialization is called, this gets initialized as well.
...               If this gets initialized, ClusterManagement gets initialized as well.
Library           SSHLibrary
Library           OperatingSystem
Resource          ${CURDIR}/ClusterManagement.robot
Resource          ${CURDIR}/SSHKeywords.robot
Variables         ${CURDIR}/../variables/Variables.py

*** Variables ***
${WORKSPACE}      /tmp
${connection_index_dict}    &{EMPTY}

*** Keywords ***
Setup_Karaf_Keywords
    [Arguments]    ${http_timeout}=${EMPTY}
    [Documentation]    Initialize ClusterManagement. Open ssh karaf connections to each ODL.
    ClusterManagement.ClusterManagement_Setup    http_timeout=${DEFAULT_TIMEOUT_HTTP}
    BuiltIn.Comment    First connections to Karaf console may fail, so WUKS is used. TODO: Track as a Bug.
    : FOR    ${index}    IN    @{ClusterManagement__member_index_list}
    \    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    3s    1s    Open_Controller_Karaf_Console_On_Background    member_index=${index}

Verify_Feature_Is_Installed
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will Succeed if the given ${feature_name} is found in the output of "feature:list -i"
    ${output} =    Issue_Command_On_Karaf_Console    feature:list -i | grep ${feature_name}    ${controller}    ${karaf_port}
    BuiltIn.Should_Contain    ${output}    ${feature_name}
    [Return]    ${output}

Issue_Command_On_Karaf_Console
    [Arguments]    ${cmd}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=10    ${loglevel}=INFO
    [Documentation]    Will execute the given ${cmd} by ssh'ing to the karaf console running on ${controller}
    ...    Note that this keyword will open&close new SSH connection, without switching back to previously current session.
    SSHLibrary.Open_Connection    ${controller}    port=${karaf_port}    prompt=${KARAF_PROMPT_LOGIN}    timeout=${timeout}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    SSHLibrary.Write    ${cmd}
    ${output}    SSHLibrary.Read_Until_Regexp    ${KARAF_PROMPT}
    SSHLibrary.Close_Connection
    BuiltIn.Log    ${output}
    [Return]    ${output}

Safe_Issue_Command_On_Karaf_Console
    [Arguments]    ${cmd}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=10    ${loglevel}=INFO
    [Documentation]    Run Issue_Command_On_Karaf_Console but restore previous connection afterwards.
    BuiltIn.Run_Keyword_And_Return    SSHKeywords.Run_Keyword_Preserve_Connection    Issue_Command_On_Karaf_Console    ${cmd}    ${controller}    ${karaf_port}    ${timeout}
    ...    ${loglevel}

Check For Elements On Karaf Command Output Message
    [Arguments]    ${cmd}    ${elements}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5
    [Documentation]    Will execute the command using Issue Command On Karaf Console then check for the given elements
    ...    in the command output message
    ${output}    Issue_Command_On_Karaf_Console    ${cmd}    ${controller}    ${karaf_port}    ${timeout}
    : FOR    ${i}    IN    @{elements}
    \    BuiltIn.Should_Contain    ${output}    ${i}

Verify_Bundle_Is_Installed
    [Arguments]    ${bundle_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will succeed if the given ${bundle name} is present in the output of "bundle:list -s "
    ${output} =    Issue_Command_On_Karaf_Console    bundle:list -s | grep ${bundle_name}    ${controller}    ${karaf_port}
    BuiltIn.Should_Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Verify_Bundle_Is_Not_Installed
    [Arguments]    ${bundle_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will succeed if the given ${bundle_name} is NOT found in the output of "bundle:list -s"
    ${output} =    Issue_Command_On_Karaf_Console    bundle:list -i | grep ${bundle_name}    ${controller}    ${karaf_port}
    BuiltIn.Should_Not_Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Check_Karaf_Log_Has_Messages
    [Arguments]    ${filter_string}    @{message_list}
    [Documentation]    Will succeed if the @{messages} are found in \ the output of "log:display"
    ${output} =    Issue_Command_On_Karaf_Console    log:display | grep ${filter_string}
    : FOR    ${message}    IN    @{message_list}
    \    BuiltIn.Should_Contain    ${output}    ${message}
    [Return]    ${output}

Install_A_Feature
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    [Documentation]    Will Install the given ${feature_name}
    BuiltIn.Log    ${timeout}
    ${output} =    Issue_Command_On_Karaf_Console    feature:install ${feature_name}    ${controller}    ${karaf_port}    ${timeout}
    BuiltIn.Log    ${output}
    [Return]    ${output}

Install_A_Feature_Using_Active_Connection
    [Arguments]    ${feature_name}
    [Documentation]    Will Install the given ${feature_name} using active connection
    ${cmd} =    BuiltIn.Set_Variable    feature:install ${feature_name}
    SSHLibrary.Write    ${cmd}
    ${output}    SSHLibrary.Read_Until_Regexp    ${KARAF_PROMPT}
    BuiltIn.Log    ${output}
    [Return]    ${output}

Uninstall_A_Feature
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    [Documentation]    Will UnInstall the given ${feature_name}
    ${output} =    Issue_Command_On_Karaf_Console    feature:uninstall ${feature_name}    ${controller}    ${karaf_port}    ${timeout}
    BuiltIn.Log    ${output}
    [Return]    ${output}

Open_Controller_Karaf_Console_On_Background
    [Arguments]    ${member_index}=${1}    ${timeout}=10    ${loglevel}=INFO
    [Documentation]    If there is a stored ssh connection index of connection to the controller's karaf console for ${member_index},
    ...    close the previous connection. In any case create a new connection
    ...    to karaf console for ${member_index}, set correct prompt set and login to karaf console.
    ...    Store connection index for ${member_index} and restore the previous active connection.
    ${current_ssh_connection_object}=    SSHLibrary.Get_Connection
    BuiltIn.Log    ${connection_index_dict}
    BuiltIn.Log    ${member_index}
    ${status}    ${old_connection_index} =    BuiltIn.Run_Keyword_And_Ignore_Error    Get From Dictionary    ${connection_index_dict}    ${member_index}
    BuiltIn.Run_Keyword_If    '${status}'=='PASS'    BuiltIn.Run_Keywords    SSHLibrary.Switch_Connection    ${old_connection_index}
    ...    AND    SSHLibrary.Close_Connection
    ${odl_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${member_index}
    SSHLibrary.Open_Connection    ${odl_ip}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT_LOGIN}    timeout=${timeout}
    ${karaf_connection_object} =    SSHLibrary.Get_Connection
    Collections.Set_To_Dictionary    ${connection_index_dict}    ${member_index}    ${karaf_connection_object.index}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    [Teardown]    SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${current_ssh_connection_object.index}

Open_Controller_Karaf_Console_With_Timeout
    [Arguments]    ${member_index}=${1}    ${timeout}=3s
    [Documentation]    Open new connection to karaf console for member index with specified timeout.
    BuiltIn.Log    ${member_index}
    ${odl_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${member_index}
    SSHLibrary.Open_Connection    ${odl_ip}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT_LOGIN}    timeout=${timeout}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}

Configure_Timeout_For_Karaf_Console
    [Arguments]    ${timeout}    ${member_index_list}=${EMPTY}
    [Documentation]    Configure a different timeout for each Karaf console.
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    ${current_connection_object} =    SSHLibrary.Get_Connection
    : FOR    ${member_index}    IN    @{index_list}    # usually: 1, 2, 3
    \    ${karaf_connection_index} =    Collections.Get_From_Dictionary    ${connection_index_dict}    ${member_index}
    \    SSHLibrary.Switch_Connection    ${karaf_connection_index}
    \    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    [Teardown]    SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${current_connection_object.index}

Execute_Controller_Karaf_Command_On_Background
    [Arguments]    ${command}    ${member_index}=${1}
    [Documentation]    Send command to karaf without affecting current SSH connection. Read, log and return response.
    ${karaf_connection_index} =    Collections.Get_From_Dictionary    ${connection_index_dict}    ${member_index}
    ${current_connection_index} =    SSHLibrary.Switch_Connection    ${karaf_connection_index}
    ${status_write}    ${message_write} =    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Write    ${command}
    ${status_wait}    ${message_wait} =    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Regexp    ${KARAF_PROMPT}
    BuiltIn.Run Keyword If    '${status_write}' != 'PASS'    BuiltIn.Fail    Failed to send the command: ${command}
    BuiltIn.Log    ${message_wait}
    BuiltIn.Run_Keyword_If    '${status_wait}' != 'PASS'    BuiltIn.Fail    Failed to see prompt after sending the command: ${command}
    [Teardown]    SSHKeywords.Restore_Current_Ssh_Connection_From_Index    ${current_connection_index}
    [Return]    ${message_wait}

Execute_Controller_Karaf_Command_With_Retry_On_Background
    [Arguments]    ${command}    ${member_index}=${1}
    [Documentation]    Attemp to send command to karaf for ${member_index}, if fail then open connection and try again.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    Execute_Controller_Karaf_Command_On_Background    ${command}    ${member_index}
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'    ${message}
    # TODO: Verify this does not leak connections indices.
    Open_Controller_Karaf_Console_On_Background    ${member_index}
    ${message} =    Execute_Controller_Karaf_Command_On_Background    ${command}    ${member_index}
    [Return]    ${message}

Log_Message_To_Controller_Karaf
    [Arguments]    ${message}    ${member_index_list}=${EMPTY}    ${tolerate_failure}=True
    [Documentation]    Make sure this resource is initialized. Send a message into the controller's karaf log file on every node listed (or all).
    ...    By default, failure while processing a node is silently ignored, unless ${tolerate_failure} is False.
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${status}    ${output} =    BuiltIn.Run_Keyword_And_Ignore_Error    Execute_Controller_Karaf_Command_With_Retry_On_Background    log:log "ROBOT MESSAGE: ${message}"    member_index=${index}
    \    BuiltIn.Run_Keyword_Unless    ${tolerate_failure} or "${status}" == "PASS"    BuiltIn.Fail    ${output}

Log_Test_Suite_Start_To_Controller_Karaf
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Log suite name to karaf log, useful in suite setup.
    Log_Message_To_Controller_Karaf    Starting suite ${SUITE_SOURCE}    ${member_index_list}

Log_Testcase_Start_To_Controller_Karaf
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Log test case name to karaf log, useful in test case setup.
    Log_Message_To_Controller_Karaf    Starting test ${TEST_NAME}    ${member_index_list}

Set_Bgpcep_Log_Levels
    [Arguments]    ${bgpcep_level}=${DEFAULT_BGPCEP_LOG_LEVEL}    ${protocol_level}=${DEFAULT_PROTOCOL_LOG_LEVEL}    ${member_index_list}=${EMPTY}
    [Documentation]    Assuming OCKCOB was used, set logging level on bgpcep and protocol loggers without affecting current SSH session.
    # FIXME: Move to appropriate Resource
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Execute_Controller_Karaf_Command_On_Background    log:set ${bgpcep_level} org.opendaylight.bgpcep    member_index=${index}
    \    Execute_Controller_Karaf_Command_On_Background    log:set ${protocol_level} org.opendaylight.protocol    member_index=${index}

Wait_For_Karaf_Log
    [Arguments]    ${message}    ${timeout}=60    ${member_index}=${1}
    [Documentation]    Read karaf logs until message appear
    # TODO: refactor this keyword to use the new workflow to account for multiple controllers.    Initial work was done
    # in this patch https://git.opendaylight.org/gerrit/#/c/45596/
    # however, the consumers of this keyword were breaking after that change.    Initial theory is that a previous
    # keyword used before this "Wait For Karaf Log" keyword was closing the karaf console connection, so the
    # "Flexible SSH Login" keyword from the patch above (45596) was failing.
    BuiltIn.Log    Waiting for '${message}' in karaf log
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT_LOGIN}    timeout=${timeout}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    SSHLibrary.Write    log:tail
    SSHLibrary.Read_Until    ${message}
    SSHLibrary.Close_Connection

Restart_Bundle
    [Arguments]    ${bundle_id}
    [Documentation]    Restarts bundle passed as argument. Note this operation is only for testing and not production environments
    # TODO: prepare this for cluster environment and multiple controllers
    Execute_Controller_Karaf_Command_With_Retry_On_Background    bundle:restart -f $(bundle:id '${bundle_id}')

Restart_Karaf
    [Documentation]    Restarts Karaf and polls log to detect when Karaf is up and running again
    # TODO: prepare this for cluster environment and multiple controllers
    Execute_Controller_Karaf_Command_With_Retry_On_Background    log:clear
    Execute_Controller_Karaf_Command_With_Retry_On_Background    shutdown -r -f
    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Wait_Until_Keyword_Succeeds    240s    60s    Wait_For_Karaf_Log    Karaf started in

Restart_Jetty
    [Documentation]    Restarts jetty bundle (to reload certificates or key/truststore information)
    Execute_Controller_Karaf_Command_With_Retry_On_Background    log:clear
    Restart_Bundle    OPS4J Pax Web - Jetty
    Wait_For_Karaf_Log    Instantiated the Application class org.opendaylight.restconf.RestconfApplication
    Wait_For_Karaf_Log    Instantiated the Application class org.opendaylight.netconf.sal.rest.impl.RestconfApplication
    Wait_For_Karaf_Log    Instantiated the Application class org.opendaylight.aaa.idm.IdmLightApplication

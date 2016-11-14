*** Settings ***
Documentation     Karaf library. This library is useful to deal with controller Karaf console for ssh sessions in cluster.
...               Running Setup Karaf Keywords is necessary. If SetupUtils initialization is called, this gets initialized as well.
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
Setup Karaf Keywords
    [Documentation]    Initialize ClusterManagement. Open ssh karaf connections to each ODL.
    ClusterManagement.ClusterManagement_Setup
    BuiltIn.Comment    First connections to Karaf console may fail, so WUKS is used. TODO: Track as a Bug.
    : FOR    ${index}    IN    @{ClusterManagement__member_index_list}
    \    BuiltIn.Wait_Until_Keyword_Succeeds    3x    0.2s    Open Controller Karaf Console On Background    member_index=${index}

Verify Feature Is Installed
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will Succeed if the given ${feature_name} is found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${controller}    ${karaf_port}
    Should Contain    ${output}    ${feature_name}
    [Return]    ${output}

Issue Command On Karaf Console
    [Arguments]    ${cmd}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5    ${loglevel}=INFO
    [Documentation]    Will execute the given ${cmd} by ssh'ing to the karaf console running on ${controller}
    ...    Note that this keyword will open&close new SSH connection, without switching back to previously current session.
    Open Connection    ${controller}    port=${karaf_port}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    Write    ${cmd}
    ${output}    Read Until    ${KARAF_PROMPT}
    Close Connection
    Log    ${output}
    [Return]    ${output}

Safe_Issue_Command_On_Karaf_Console
    [Arguments]    ${cmd}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5    ${loglevel}=INFO
    [Documentation]    Run Issue_Command_On_Karaf_Console but restore previous connection afterwards.
    BuiltIn.Run_Keyword_And_Return    SSHKeywords.Run_Keyword_Preserve_Connection    Issue_Command_On_Karaf_Console    ${cmd}    ${controller}    ${karaf_port}    ${timeout}
    ...    ${loglevel}

Check For Elements On Karaf Command Output Message
    [Arguments]    ${cmd}    ${elements}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5
    [Documentation]    Will execute the command using Issue Command On Karaf Console then check for the given elements
    ...    in the command output message
    ${output}    Issue Command On Karaf Console    ${cmd}    ${controller}    ${karaf_port}    ${timeout}
    : FOR    ${i}    IN    @{elements}
    \    Should Contain    ${output}    ${i}

Verify Bundle Is Installed
    [Arguments]    ${bundle_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will succeed if the given ${bundle name} is present in the output of "bundle:list -s "
    ${output}=    Issue Command On Karaf Console    bundle:list -s | grep ${bundle_name}    ${controller}    ${karaf_port}
    Should Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Verify Bundle Is Not Installed
    [Arguments]    ${bundle_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will succeed if the given ${bundle_name} is NOT found in the output of "bundle:list -s"
    ${output}=    Issue Command On Karaf Console    bundle:list -i | grep ${bundle_name}    ${controller}    ${karaf_port}
    Should Not Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Check Karaf Log Has Messages
    [Arguments]    ${filter_string}    @{message_list}
    [Documentation]    Will succeed if the @{messages} are found in \ the output of "log:display"
    ${output}=    Issue Command On Karaf Console    log:display | grep ${filter_string}
    : FOR    ${message}    IN    @{message_list}
    \    Should Contain    ${output}    ${message}
    [Return]    ${output}

Install a Feature
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    [Documentation]    Will Install the given ${feature_name}
    Log    ${timeout}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    ${controller}    ${karaf_port}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Uninstall a Feature
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    [Documentation]    Will UnInstall the given ${feature_name}
    ${output}=    Issue Command On Karaf Console    feature:uninstall ${feature_name}    ${controller}    ${karaf_port}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Open Controller Karaf Console On Background
    [Arguments]    ${member_index}=${1}
    [Documentation]    If there is a stored ssh connection index of connection to the controller's karaf console for ${member_index},
    ...    close the previous connection. In any case create a new connection
    ...    to karaf console for ${member_index}, set correct prompt set and login to karaf console.
    ...    Store connection index for ${member_index} and restore the previous active connection.
    ${current_ssh_connection_object}=    SSHLibrary.Get Connection
    BuiltIn.Log    ${connection_index_dict}
    BuiltIn.Log    ${member_index}
    ${status}    ${old_connection_index} =    BuiltIn.Run Keyword And Ignore Error    Get From Dictionary    ${connection_index_dict}    ${member_index}
    BuiltIn.Run Keyword If    '${status}'=='PASS'    BuiltIn.Run Keywords    SSHLibrary.Switch Connection    ${old_connection_index}
    ...    AND    SSHLibrary.Close Connection
    ${odl_ip}=    ClusterManagement.Resolve_IP_Address_For_Member    ${member_index}
    SSHLibrary.Open Connection    ${odl_ip}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_DETAILED_PROMPT}
    ${karaf_connection_object}=    SSHLibrary.Get Connection
    Collections.Set To Dictionary    ${connection_index_dict}    ${member_index}    ${karaf_connection_object.index}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    [Teardown]    SSHKeywords.Restore Current SSH Connection From Index    ${current_ssh_connection_object.index}

Configure Timeout For Karaf Console
    [Arguments]    ${timeout}    ${member_index_list}=${EMPTY}
    [Documentation]    Configure a different timeout for each Karaf console.
    ${index_list} =    ClusterManagement.ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    ${current_connection_object}=    SSHLibrary.Get Connection
    : FOR    ${member_index}    IN    @{index_list}    # usually: 1, 2, 3
    \    ${karaf_connection_index}=    Collections.Get From Dictionary    ${connection_index_dict}    ${member_index}
    \    SSHLibrary.Switch Connection    ${karaf_connection_index}
    \    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    [Teardown]    SSHKeywords.Restore Current SSH Connection From Index    ${current_connection_object.index}

Execute Controller Karaf Command On Background
    [Arguments]    ${command}    ${member_index}=${1}
    [Documentation]    Send command to karaf without affecting current SSH connection. Read, log and return response.
    ${karaf_connection_index}=    Collections.Get From Dictionary    ${connection_index_dict}    ${member_index}
    ${current_connection_index}=    SSHLibrary.Switch Connection    ${karaf_connection_index}
    ${status_write}    ${message_write}=    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Write    ${command}
    ${status_wait}    ${message_wait}=    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Read Until Prompt
    BuiltIn.Run Keyword If    '${status_write}' != 'PASS'    BuiltIn.Fail    Failed to send the command: ${command}
    BuiltIn.Log    ${message_wait}
    BuiltIn.Run Keyword If    '${status_wait}' != 'PASS'    BuiltIn.Fail    Failed to see prompt after sending the command: ${command}
    [Teardown]    SSHKeywords.Restore Current SSH Connection From Index    ${current_connection_index}
    [Return]    ${message_wait}

Execute Controller Karaf Command With Retry On Background
    [Arguments]    ${command}    ${member_index}=${1}
    [Documentation]    Attemp to send command to karaf for ${member_index}, if fail then open connection and try again.
    ${status}    ${message}=    BuiltIn.Run Keyword And Ignore Error    Execute Controller Karaf Command On Background    ${command}    ${member_index}
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'    ${message}
    # TODO: Verify this does not leak connections indices.
    Open Controller Karaf Console On Background    ${member_index}
    ${message}=    Execute Controller Karaf Command On Background    ${command}    ${member_index}
    [Return]    ${message}

Log Message To Controller Karaf
    [Arguments]    ${message}    ${member_index_list}=${EMPTY}
    [Documentation]    Make sure this resource is initialized. Send a message into the controller's karaf log file on every node listed (or all).
    ${index_list} =    ClusterManagement.ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Execute Controller Karaf Command With Retry On Background    log:log "ROBOT MESSAGE: ${message}"    member_index=${index}

Log Test Suite Start To Controller Karaf
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Log suite name to karaf log, useful in suite setup.
    Log Message To Controller Karaf    Starting suite ${SUITE_SOURCE}    ${member_index_list}

Log Testcase Start To Controller Karaf
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Log test case name to karaf log, useful in test case setup.
    Log Message To Controller Karaf    Starting test ${TEST_NAME}    ${member_index_list}

Set Bgpcep Log Levels
    [Arguments]    ${bgpcep_level}=${DEFAULT_BGPCEP_LOG_LEVEL}    ${protocol_level}=${DEFAULT_PROTOCOL_LOG_LEVEL}    ${member_index_list}=${EMPTY}
    [Documentation]    Assuming OCKCOB was used, set logging level on bgpcep and protocol loggers without affecting current SSH session.
    # FIXME: Move to appropriate Resource
    ${index_list} =    ClusterManagement.ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Execute Controller Karaf Command On Background    log:set ${bgpcep_level} org.opendaylight.bgpcep    member_index=${index}
    \    Execute Controller Karaf Command On Background    log:set ${protocol_level} org.opendaylight.protocol    member_index=${index}

Wait For Karaf Log
    [Arguments]    ${message}    ${timeout}=60    ${member_index}=${1}
    [Documentation]    Read karaf logs until message appear
    # TODO: refactor this keyword to use the new workflow to account for multiple controllers.    Initial work was done
    # in this patch https://git.opendaylight.org/gerrit/#/c/45596/
    # however, the consumers of this keyword were breaking after that change.    Initial theory is that a previous
    # keyword used before this "Wait For Karaf Log" keyword was closing the karaf console connection, so the
    # "Flexible SSH Login" keyword from the patch above (45596) was failing.
    Log    Waiting for '${message}' in karaf log
    Open Connection    ${ODL_SYSTEM_IP}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Login    ${KARAF_USER}    ${KARAF_PASSWORD}    loglevel=${loglevel}
    Write    log:tail
    Read Until    ${message}
    Close Connection

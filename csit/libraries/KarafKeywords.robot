*** Settings ***
Documentation     Karaf library. This library is useful to deal with controller Karaf console.
Library           SSHLibrary
Library           OperatingSystem
Resource          ${CURDIR}/SSHKeywords.robot
Variables         ${CURDIR}/../variables/Variables.py

*** Variables ***
${WORKSPACE}      /tmp
${KarafKeywords__karaf_connection_index}    -1

*** Keywords ***
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
    [Documentation]    Connect to the controller's karaf console, but do not switch to it.
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_DETAILED_PROMPT}
    ${karaf_connection}=    SSHLibrary.Get Connection
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    BuiltIn.Set Suite Variable    ${KarafKeywords__karaf_connection_index}    ${karaf_connection.index}
    [Teardown]    SSHKeywords.Restore Current SSH Connection From Index    ${current_ssh_connection.index}

Configure Timeout For Karaf Console
    [Arguments]    ${timeout}
    [Documentation]    Configure a different timeout for the Karaf console
    BuiltIn.Run Keyword If    ${KarafKeywords__karaf_connection_index} == -1    Fail    Need to connect to a Karaf Console first
    ${current_connection_index}=    SSHLibrary.Switch Connection    ${KarafKeywords__karaf_connection_index}
    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    [Teardown]    SshKeywords.Restore Current SSH Connection From Index    ${current_connection_index}

Execute Controller Karaf Command On Background
    [Arguments]    ${command}
    [Documentation]    Send command to karaf without affecting current SSH connection. Read, log and return response.
    ...    This assumes Karaf connection has index saved and correct prompt set.
    BuiltIn.Run Keyword If    ${KarafKeywords__karaf_connection_index} == -1    Fail    Need to connect to a Karaf Console first
    ${current_connection_index}=    SSHLibrary.Switch Connection    ${KarafKeywords__karaf_connection_index}
    ${status_write}    ${message_write}=    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Write    ${command}
    ${status_wait}    ${message_wait}=    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Read Until Prompt
    BuiltIn.Run Keyword If    '${status_write}' != 'PASS'    BuiltIn.Fail    Failed to send the command: ${command}
    BuiltIn.Log    ${message_wait}
    BuiltIn.Run Keyword If    '${status_wait}' != 'PASS'    BuiltIn.Fail    Failed to see prompt after sending the command: ${command}
    [Teardown]    SshKeywords.Restore Current SSH Connection From Index    ${current_connection_index}
    [Return]    ${message_wait}

Execute Controller Karaf Command With Retry On Background
    [Arguments]    ${command}
    [Documentation]    Attemp to send command to karaf, if fail then open connection and try again.
    # As an attempt to debug intermittent SSH failures in the karaf logging command, we want to know the avail entropy on the controller system
    Run Command On Controller    cmd=cat /proc/sys/kernel/random/entropy_avail
    ${status}    ${message}=    BuiltIn.Run Keyword And Ignore Error    Execute Controller Karaf Command On Background    ${command}
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'    ${message}
    # TODO: Verify this does not leak connections indices.
    Open Controller Karaf Console On Background
    ${message}=    Execute Controller Karaf Command On Background    ${command}
    [Return]    ${message}

Log Message To Controller Karaf
    [Arguments]    ${message}
    [Documentation]    Send a message into the controller's karaf log file. Do not change current SSH connection.
    ${reply}=    Execute Controller Karaf Command With Retry On Background    log:log "ROBOT MESSAGE: ${message}"
    [Return]    ${reply}

Log Test Suite Start To Controller Karaf
    [Documentation]    Log suite name to karaf log, useful in suite setup.
    Log Message To Controller Karaf    Starting suite ${SUITE_SOURCE}

Log Testcase Start To Controller Karaf
    [Documentation]    Log test case name to karaf log, useful in test case setup.
    Log Message To Controller Karaf    Starting test ${TEST_NAME}

Set Bgpcep Log Levels
    [Arguments]    ${bgpcep_level}=${DEFAULT_BGPCEP_LOG_LEVEL}    ${protocol_level}=${DEFAULT_PROTOCOL_LOG_LEVEL}
    [Documentation]    Assuming OCKCOB was used, set logging level on bgpcep and protocol loggers without affecting current SSH session.
    # FIXME: Move to appropriate Resource
    Execute Controller Karaf Command On Background    log:set ${bgpcep_level} org.opendaylight.bgpcep
    Execute Controller Karaf Command On Background    log:set ${protocol_level} org.opendaylight.protocol

Wait For Karaf Log
    [Arguments]    ${message}    ${timeout}=60
    [Documentation]    Read karaf logs until message appear
    Log    Waiting for '${message}' in karaf log
    Open Connection    ${ODL_SYSTEM_IP}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Flexible SSH Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    log:tail
    Read Until    ${message}
    Close Connection

*** Settings ***
Library           SSHLibrary
Library           OperatingSystem
Variables         ../variables/Variables.py

*** Variables ***
${WORKSPACE}      /tmp
${BUNDLEFOLDER}    distribution-karaf-0.3.0-SNAPSHOT
${KarafKeywords__controller_index}    -1

*** Keywords ***
Check Karaf Log File Does Not Have Messages
    [Arguments]    ${ip}    ${message}    ${user}=${CONTROLLER_USER}    ${password}=${CONTROLLER_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    [Documentation]    Fails if the provided ${message} is found in the karaf.log file. Uses grep to search. The
    ...    karaf.log file can be overridden with ${log_file} to be any file on the given system @ ${ip}
    ${output}=    Run Command On Controller    ${ip}    grep ${message} ${log_file}    user=${user}    password=${password}    prompt=${prompt}
    Should Not Contain    ${output}    ${message}

Verify Feature Is Installed
    [Arguments]    ${feature_name}    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will Succeed if the given ${feature_name} is found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${controller}    ${karaf_port}
    Should Contain    ${output}    ${feature_name}
    [Return]    ${output}

Verify Feature Is Not Installed
    [Arguments]    ${feature_name}    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will Succeed if the given ${feature_name} is NOT found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${controller}    ${karaf_port}
    Should Not Contain    ${output}    ${feature_name}
    [Return]    ${output}

Issue Command On Karaf Console
    [Arguments]    ${cmd}    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5
    [Documentation]    Will execute the given ${cmd} by ssh'ing to the karaf console running on ${CONTROLLER}
    Open Connection    ${controller}    port=${karaf_port}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    ${cmd}
    ${output}    Read Until    ${KARAF_PROMPT}
    Close Connection
    Log    ${output}
    [Return]    ${output}

Verify Bundle Is Installed
    [Arguments]    ${bundle_name}    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will succeed if the given ${bundle name} is present in the output of "bundle:list -s "
    ${output}=    Issue Command On Karaf Console    bundle:list -s | grep ${bundle_name}    ${controller}    ${karaf_port}
    Should Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Verify Bundle Is Not Installed
    [Arguments]    ${bundle_name}    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
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
    [Arguments]    ${feature_name}    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=15
    [Documentation]    Will Install the given ${feature_name}
    Log    ${timeout}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    ${controller}    ${karaf_port}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Uninstall a Feature
    [Arguments]    ${feature_name}    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=15
    [Documentation]    Will UnInstall the given ${feature_name}
    ${output}=    Issue Command On Karaf Console    feature:uninstall ${feature_name}    ${controller}    ${karaf_port}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Get Current SSH Connection Index
    ${current}=    SSHLibrary.Get Connection
    [Return]    ${current.index}

Restore Current SSH Connection
    [Arguments]    ${index}
    # There is a bug in SSHLibrary: Invoking "SSHLibrary.Switch_Connection"
    # and passing None as the "index_or_alias" argument to it has exactly the
    # same effect as invoking "Close Connection". Thus it is unsafe to
    # "obtain the index of the currently active SSH connection, switch to
    # another one, do whatever is necessary with it and then use
    # "SSHLibrary.Switch_Connection" to reinstate the old active connection
    # won't work properly, because the "obtain the index of the currently
    # active SSH connection" part of the workflow will return None if there
    # was no active connection. The solution is to use this keyword instead
    # of "SSHLibrary.Switch_Connection" which restores the "no connection
    # active" state correctly. Unfortunately this will fail if run on Jython
    # and there is no SSH server running on localhost, port 22 but there is
    # nothing easy that can be done about it.
    BuiltIn.Run Keyword And Return If    ${index} is not None    SSHLibrary.Switch Connection    ${index}
    SSHLibrary.Open Connection    127.0.0.1
    SSHLibrary.Close Connection

Switch SSH To Current Karaf Console
    Create Dummy Connection To Bypass SSHLibrary Bug
    SSHLibrary.Switch Connection    ${KarafKeywords__controller_index}

Open Controller Karaf Console
    [Documentation]    Connect to the controller's karaf console.
    ${current_SSH_connection}=    Get Current SSH Connection Index
    ${esc}=    BuiltIn.Evaluate    chr(int(27))
    ${prompt}=    Builtin.Set Variable    @${esc}[0m${esc}[34mroot${esc}[0m>
    SSHLibrary.Open Connection    ${CONTROLLER}    port=${KARAF_SHELL_PORT}    prompt=${prompt}
    ${connection}=    Get Current SSH Connection Index
    BuiltIn.Set Suite Variable    ${KarafKeywords__controller_index}    ${connection}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Restore Current SSH Connection    ${current_SSH_connection}

Log Message To Controller Karaf
    [Arguments]    ${message}
    [Documentation]    Send a message into the controller's karaf log file.
    BuiltIn.Run Keyword If    ${KarafKeywords__controller_index} == -1    Fail    Need to connect to a Karaf Console first
    ${current_SSH_connection}=    Get Current SSH Connection Index
    SSHLibrary.Switch Connection    ${KarafKeywords__controller_index}
    ${status_write}    ${message_write}=    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Write    log:log "ROBOT MESSAGE: ${message}"
    ${status_wait}    ${message_wait}=    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Read Until Prompt
    Restore Current SSH Connection    ${current_SSH_connection}
    BuiltIn.Run Keyword If    '${status_write}' != 'PASS'    BuiltIn.Fail    Failed to send the command: ${message}
    BuiltIn.Run Keyword If    '${status_wait}' != 'PASS'    BuiltIn.Fail    Failed to see prompt after sending the command: ${message}

Log Test Suite Start To Controller Karaf
    Log Message To Controller Karaf    Starting suite ${SUITE_SOURCE}

Log Testcase Start To Controller Karaf
    Log Message To Controller Karaf    Starting test ${TEST_NAME}

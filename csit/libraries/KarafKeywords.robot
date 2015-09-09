*** Settings ***
Library           SSHLibrary
Library           OperatingSystem
Variables         ../variables/Variables.py

*** Variables ***
${WORKSPACE}      /tmp
${BUNDLEFOLDER}    distribution-karaf-0.3.0-SNAPSHOT

*** Keywords ***
Check Karaf Log File Does Not Have Messages
    [Arguments]    ${ip}    ${message}    ${user}=${CONTROLLER_USER}    ${password}=${CONTROLLER_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    [Documentation]    Fails if the provided ${message} is found in the karaf.log file.  Uses grep to search.  The
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

Connect To Controller Karaf
    [Documentation]    Connect to the controller's karaf console.
    ${esc}=    BuiltIn.Evaluate    chr(int(27))
    ${prompt}=    Builtin.Set Variable    @${esc}[0m${esc}[34mroot${esc}[0m>
    ${connection}=    SSHLibrary.Open_Connection    ${CONTROLLER}    port=${KARAF_SHELL_PORT}    prompt=${prompt}
    Set Suite Variable    ${controller_index}    ${connection}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}

Log Message To Controller Karaf
    [Arguments]    ${message}
    [Documentation]    Send a message into the controller's karaf log file.
    # Background info: If there was no previous SSH connection, the "Get
    # Connection" returns an information structure whose "index" field
    # resolves to "None", and the "Switch Connection" below does not
    # complain.
    ${current}=    Get_Connection
    ${connection}=    Set Variable    ${current.index}
    BuiltIn.Run Keyword If    ${controller_index} <> -1    Switch Connection    ${controller_index}
    BuiltIn.Run Keyword If    ${controller_index} == -1    Connect to Controller Karaf
    SSHLibrary.Write    log:log "ROBOT MESSAGE: ${message}"
    SSHLibrary.Read_Until_Prompt
    Switch Connection    ${connection}

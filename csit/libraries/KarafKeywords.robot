*** Settings ***
Library           SSHLibrary
Library           OperatingSystem
Variables         ../variables/Variables.py

*** Variables ***
${WORKSPACE}      /tmp
${BUNDLEFOLDER}    distribution-karaf-0.3.0-SNAPSHOT
${current_console}    -1

*** Keywords ***
Check Karaf Log File Does Not Have Messages
    [Arguments]    ${ip}    ${message}    ${user}=${CONTROLLER_USER}    ${password}=${CONTROLLER_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    [Documentation]    Fails if the provided ${message} is found in the karaf.log file.  Uses grep to search.  The
    ...    karaf.log file can be overridden with ${log_file} to be any file on the given system @ ${ip}
    ${output}=    Run Command On Controller    ${ip}    grep ${message} ${log_file}    user=${user}    password=${password}    prompt=${prompt}
    Should Not Contain    ${output}    ${message}

Get Current Connection Index
    ${current}=    Get Connection
    ${connection}=    Set Variable    ${current.index}
    [Return]    ${connection}

Switch To Karaf Console Connection
    [Arguments]    ${console}
    ${connection}=    Get Current Connection Index
    Switch Connection    ${console}

Open Karaf Console
    [Arguments]    ${controller}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5
    [Documentation]    Connect to the controller's karaf console and make it the default one.
    ...    karaf console. Returns the console index which can be used in subsequent commands.
    ...    Takes care to not change the default SSH connection.
    # Background info: If there was no previous SSH connection, the "Get
    # Current Connection Index" returns "None" (because the Get
    # Connection used inside returns an information structure whose
    # "index" field resolves to "None"), and the "Switch Connection"
    # below does not complain.
    ${original_connection}=    Get Current Connection Index
    ${esc}=    BuiltIn.Evaluate    chr(int(27))
    ${karaf_prompt}    Set Variable    @${esc}[0m${esc}[34mroot${esc}[0m>
    ${connection}=    Open Connection    ${controller}    port=${karaf_port}    prompt=${karaf_prompt}    timeout=${timeout}
    Set Suite Variable    ${current_console}    ${connection}
    Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Switch Connection    ${original_connection}
    [Return]    ${connection}

Switch To Karaf Console
    [Arguments]    ${console}
    [Documentation]    Make the specified Karaf console connection the default one.
    Set Suite Variable    ${current_console}    ${connection}

Close Karaf Console
    [Arguments]    ${console}=${current_console}
    [Documentation]    Close the specified Karaf console connection. Leaves the default SSH connection
    ...    intact.
    ${original_connection}=    Switch To Karaf Console Connection    ${console}
    Close Connection
    Run Keyword If    ${current_console} == ${console}    ${current_console}=    Set Variable    -1
    Switch Connection    ${original_connection}

Issue Command On Karaf Console
    [Arguments]    ${cmd}    ${console}=${current_console}
    [Documentation]    Execute the given ${cmd} by sending it through ssh to the connection and then
    ...    reading the content until the prompt is seen. Makes sure that the current SSH connection
    ...    is not changed. If no console connection is specified and no console connection is the
    ...    default one, then it connects to the default Karaf instance and makes that connection
    ...    the current one.
    Run Keyword If    ${console} == -1    Open Karaf Console
    Run Keyword If    ${console} == -1    ${console}=    Set Variable    ${current_console}
    ${original_connection}=    Switch To Karaf Console Connection    ${console}
    Write    ${cmd}
    ${output}=    Read Until Prompt
    Log    ${output}
    Switch Connection    ${original_connection}
    [Return]    ${output}

Verify Feature Is Installed
    [Arguments]    ${feature_name}    ${console}=${current_console}
    [Documentation]    Will Succeed if the given ${feature_name} is found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${console}
    Should Contain    ${output}    ${feature_name}
    [Return]    ${output}

Verify Feature Is Not Installed
    [Arguments]    ${feature_name}    ${console}=${current_console}
    [Documentation]    Will Succeed if the given ${feature_name} is NOT found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${console}
    Should Not Contain    ${output}    ${feature_name}
    [Return]    ${output}

Verify Bundle Is Installed
    [Arguments]    ${bundle_name}    ${console}=${current_console}
    [Documentation]    Will succeed if the given ${bundle name} is present in the output of "bundle:list -s "
    ${output}=    Issue Command On Karaf Console    bundle:list -s | grep ${bundle_name}    ${console}
    Should Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Verify Bundle Is Not Installed
    [Arguments]    ${bundle_name}    ${console}=${current_console}
    [Documentation]    Will succeed if the given ${bundle_name} is NOT found in the output of "bundle:list -s"
    ${output}=    Issue Command On Karaf Console    bundle:list -i | grep ${bundle_name}    ${console}
    Should Not Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Check Karaf Log Has Messages
    [Arguments]    ${filter_string}    @{message_list}    ${console}=${current_console}
    [Documentation]    Will succeed if the @{messages} are found in \ the output of "log:display"
    ${output}=    Issue Command On Karaf Console    log:display | grep ${filter_string}    ${console}
    : FOR    ${message}    IN    @{message_list}
    \    Should Contain    ${output}    ${message}
    [Return]    ${output}

Install a Feature
    [Arguments]    ${feature_name}    ${console}=${current_console}
    [Documentation]    Will Install the given ${feature_name}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    ${console}
    Log    ${output}
    [Return]    ${output}

Uninstall a Feature
    [Arguments]    ${feature_name}    ${console}=${current_console}
    [Documentation]    Will UnInstall the given ${feature_name}
    ${output}=    Issue Command On Karaf Console    feature:uninstall ${feature_name}    ${console}
    Log    ${output}
    [Return]    ${output}

Log Message To Controller Karaf
    [Arguments]    ${message}    ${console}=${current_console}
    [Documentation]    Send a message into the controller's karaf log file.
    ${output}=    Issue Command On Karaf Console    log:log "ROBOT MESSAGE: ${message}"    ${console}
    Log    ${output}
    [Return]    ${output}

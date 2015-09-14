*** Settings ***
Library           SSHLibrary
Library           OperatingSystem
Variables         ../variables/Variables.py

*** Variables ***
${WORKSPACE}      /tmp
${BUNDLEFOLDER}    distribution-karaf-0.3.0-SNAPSHOT
${current_console}    None

*** Keywords ***
Check Karaf Log File Does Not Have Messages
    [Arguments]    ${ip}    ${message}    ${user}=${CONTROLLER_USER}    ${password}=${CONTROLLER_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    [Documentation]    Fails if the provided ${message} is found in the karaf.log file.  Uses grep to search.  The
    ...    karaf.log file can be overridden with ${log_file} to be any file on the given system @ ${ip}
    ${output}=    Run Command On Controller    ${ip}    grep ${message} ${log_file}    user=${user}    password=${password}    prompt=${prompt}
    Should Not Contain    ${output}    ${message}

Store Current SSH Connection
    [Documentation]    DO NOT USE THIS DIRECTLY !
    # Background info: If there was no previous SSH connection, the "Get
    # Connection" returns an information structure whose "index" field
    # resolves to "None", and the "Switch Connection" in the next keyword
    # does not complain.
    ${current}=    Get_Connection
    Set Suite Variable    ${current_SSH_connection}    ${current.index}

Restore Current SSH Connection
    [Documentation]    DO NOT USE THIS DIRECTLY !
    Switch Connection    ${current_SSH_connection}

Open Controller Karaf Console
    [Arguments]    ${addr}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5
    [Documentation]    Connect to the controller's karaf console.
    Store Current SSH Connection
    ${esc}=    BuiltIn.Evaluate    chr(int(27))
    ${prompt}=    Builtin.Set Variable    @${esc}[0m${esc}[34mroot${esc}[0m>
    ${connection}=    SSHLibrary.Open_Connection    ${addr}    port=${karaf_port}    prompt=${prompt}    timeout=${timeout}
    Set Suite Variable    ${current_console}    ${connection}
    SSHLibrary.Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Restore Current SSH Connection

Get Controller Name Or Index
    [Arguments]    ${addr}=None    ${console_index}=None
    [Documentation]    DO NOT USE THIS DIRECTLY !
    Return From Keyword If    ${console_index} <> None    ${console_index}    None
    Return From Keyword If    ${addr} <> None    None    ${addr}
    Return From Keyword If    ${current_console} <> None    ${current_console}    None
    Return From Keyword    None    ${CONTROLLER}

Issue Command On Karaf Console
    [Arguments]    ${cmd}    ${addr}=None    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5    ${console_index}=None
    [Documentation]    Will execute the given ${cmd} by ssh'ing to the karaf console. If {console_index} is
    ...    given, then the command is sent to that console. Otherwise if ${addr} is given, then a connection
    ...    is opened to that controller, the command is sent there and then the connection is closed. If a cosole
    ...    was opened using "Open Controller Karaf Console", then the command is sent to that console. Otherwise
    ...    the command is sent to ${CONTROLLER} using a temporary connection that will be closed after the command
    ...    is sent. The arguments ${karaf_port} and ${timeout} are ignored if a console index is being used (in
    ...    that case the values specified in the connection are used instead.
    Store Current SSH Connection
    ${index}    ${console}=    Get Controller Name Or Index    ${addr}    ${console_index}
    Run Keyword If    ${index} <> None    Switch Connection    ${index}
    Run Keyword If    ${index} == None    Open Connection    ${console}    port=${karaf_port}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Run Keyword If    ${index} == None    Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    ${cmd}
    ${output}    Read Until    ${KARAF_PROMPT}
    Run Keyword If    ${index} == None    Close Connection
    Log    ${output}
    Restore Current SSH Connection
    [Return]    ${output}

Verify Feature Is Installed
    [Arguments]    ${feature_name}    ${addr}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will Succeed if the given ${feature_name} is found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${addr}    ${karaf_port}
    Should Contain    ${output}    ${feature_name}
    [Return]    ${output}

Verify Feature Is Not Installed
    [Arguments]    ${feature_name}    ${addr}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will Succeed if the given ${feature_name} is NOT found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${addr}    ${karaf_port}
    Should Not Contain    ${output}    ${feature_name}
    [Return]    ${output}

Verify Bundle Is Installed
    [Arguments]    ${bundle_name}    ${addr}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will succeed if the given ${bundle name} is present in the output of "bundle:list -s "
    ${output}=    Issue Command On Karaf Console    bundle:list -s | grep ${bundle_name}    ${addr}    ${karaf_port}
    Should Contain    ${output}    ${bundle_name}
    [Return]    ${output}

Verify Bundle Is Not Installed
    [Arguments]    ${bundle_name}    ${addr}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will succeed if the given ${bundle_name} is NOT found in the output of "bundle:list -s"
    ${output}=    Issue Command On Karaf Console    bundle:list -i | grep ${bundle_name}    ${addr}    ${karaf_port}
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
    [Arguments]    ${feature_name}    ${addr}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=15    ${console_index}=None
    [Documentation]    Will Install the given ${feature_name}
    Log    ${timeout}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    ${addr}    ${karaf_port}    ${timeout}    ${console_index}
    Log    ${output}
    [Return]    ${output}

Uninstall a Feature
    [Arguments]    ${feature_name}    ${addr}=${CONTROLLER}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=15    ${console_index}=None
    [Documentation]    Will UnInstall the given ${feature_name}
    ${output}=    Issue Command On Karaf Console    feature:uninstall ${feature_name}    ${addr}    ${karaf_port}    ${timeout}    ${console_index}
    Log    ${output}
    [Return]    ${output}

Log Message To Controller Karaf
    [Arguments]    ${message}    ${addr}=None    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=5    ${console_index}=None
    [Documentation]    Send a message into the controller's karaf log file.
    Issue Command On Karaf Console    log:log "ROBOT MESSAGE: ${message}"    ${addr}    ${karaf_port}    ${timeout}    ${console_index}

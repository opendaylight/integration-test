*** Settings ***
Documentation     Karaf library. This library is useful to deal with controller Karaf console for ssh sessions in cluster.
...               Running Setup Karaf Keywords is necessary.
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

Check Karaf Log File Does Not Have Messages
    [Arguments]    ${ip}    ${message}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    [Documentation]    Fails if the provided ${message} is found in the karaf.log file. Uses grep to search. The
    ...    karaf.log file can be overridden with ${log_file} to be any file on the given system @ ${ip}
    ${output}=    Run Command On Controller    ${ip}    grep -c '${message}' ${log_file}    user=${user}    password=${password}    prompt=${prompt}
    Should Be Equal As Strings    ${output}    0

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

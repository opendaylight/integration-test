*** Settings ***
Documentation     General Utils library. This library has broad scope, it can be used by any robot system tests.
Library           SSHLibrary
Library           String
Library           DateTime
Library           Process
Library           Collections
Library           RequestsLibrary
Library           ./UtilLibrary.py
Resource          KarafKeywords.robot
Variables         ../variables/Variables.py


*** Variables ***
${start}   sudo  mn --controller remote --mac

${feature_name}    odl-usecplugin

*** Keywords ***
Start Suite
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${timeout}=30s   
    [Documentation]    Basic setup
    Log    Start Suite
    Install Usecplugin Feature    ${feature_name}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    180
    sleep    30 
    Verify Feature Usecplugin is Installed    ${feature_name}  
   
Install Usecplugin Feature
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    [Documentation]    Will Install the given ${feature_name}
    Log    ${timeout}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    ${controller}    ${karaf_port}    ${timeout}
    Log    ${output}
    [Return]    ${output}


Verify Feature Usecplugin is Installed
    [Arguments]    ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}
    [Documentation]    Will Succeed if the given ${feature_name} is found in the output of "feature:list -i"
    ${output}=    Issue Command On Karaf Console    feature:list -i | grep ${feature_name}    ${controller}    ${karaf_port}
    Log    ${output}
    Should Contain    ${output}    ${feature_name}
    [Return]    ${output}


Stop Suite
    [Arguments]    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Log    Stop Suite
    



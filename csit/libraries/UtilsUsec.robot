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

${feature_name_aaa}    odl-usecplugin-aaa
${feature_name_openflow}    odl-usecplugin-openflow


*** Keywords ***
Start Suite
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${timeout}=30s   
    [Documentation]    Basic setup
    Log    Start Suite
    Install OpenFlow Feature    ${feature_name_openflow}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    180
    sleep     60
    Install AAA Feature    ${feature_name_aaa}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    180
    sleep    60

Install AAA Feature
    [Arguments]    ${feature_name_aaa}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    [Documentation]    Will Install the given ${feature_name_aaa}
    Log    ${timeout}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name_aaa}    ${controller}    ${karaf_port}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Install OpenFlow Feature
    [Arguments]    ${feature_name_openflow}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=180
    [Documentation]    Will Install the given ${feature_name_openflow}
    Log    Openflow feature
    Log    ${timeout}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name_openflow}    ${controller}    ${karaf_port}    ${timeout}
    Log    ${output}
    [Return]    ${output}
     

Stop Suite
    [Arguments]    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Log    Stop Suite
    



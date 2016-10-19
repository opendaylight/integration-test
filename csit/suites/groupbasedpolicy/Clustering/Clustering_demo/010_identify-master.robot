 
*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           String
Variables         ../../../../variables/Variables.py
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot

*** Variables ***
${GBP_INSTANCE_COUNT}    ${0}
${VBD_INSTANCE_COUNT}    ${0}
@{ODL_SYSTEMS}
...    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
${ODL_GBP_FEATURE_PREFIX}    odl-groupbasedpolicy-
@{FEATURES_TO_INSTALL}
...    ${ODL_GBP_FEATURE_PREFIX}ofoverlay
@{FEATURES_DEPENDENT}
...    ${ODL_GBP_FEATURE_PREFIX}base

*** Test Cases ***
Identify GBP Master Instance
    Log Many   ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Wait Until Keyword Succeeds    10x    10 sec    Search For Gbp Master    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Should Be Equal As Integers   ${GBP_INSTANCE_COUNT}    1
    Log    GBP ${GBP_MASTER_IP}, VBD ${VBD_MASTER_IP}
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}

Install Features On GBP Master
    : FOR    ${feature}    IN    @{FEATURES_TO_INSTALL}
    \    Log    Installing ${feature}
    \    ${installed}=    Is Feature Installed    ${feature}    ${GBP_MASTER_IP}
    \    Log    installed:${installed}
    \    Should Not Be True    ${installed}
    \    Install Feature On IP    ${feature}    ${GBP_MASTER_IP}
    \    ${installed}=    Is Feature Installed    ${feature}    ${GBP_MASTER_IP}
    \    Log    installed:${installed}
    \    Should Be True    ${installed}

Check Dependent Features On GBP Master
    : FOR    ${feature}    IN    @{FEATURES_DEPENDENT}
    \    ${installed}=    Is Feature Installed    ${feature}    ${GBP_MASTER_IP}
    \    Log    installed:${installed}
    \    Should Be True    ${installed}

Unistall Features On GBP Master
    : FOR    ${feature}    IN    @{FEATURES_TO_INSTALL}
    \    Log    Uninstalling ${feature}
    \    Uninstall Feature On IP    ${feature}    ${GBP_MASTER_IP}
    \    ${installed}=    Is Feature Installed    ${feature}    ${GBP_MASTER_IP}
    \    Log    installed:${installed}
    \    Should Not Be True    ${installed}

Find Features On ODL System
    ${number_of_installations}=    Set Variable    ${0}
    : FOR    ${ip}    IN    @{ODL_SYSTEMS}
    \    Continue For Loop If    '${ip}' == '${GBP_MASTER_IP}'
    \    Log    current IP:${ip}
    \    ${all_installed}=    Check Features Installed On IP    ${ip}
    \    Log    all_in:${all_installed}
    \    ${number_of_installations}=    Run Keyword If    ${all_installed}    Set Variable    ${number_of_installations+1}
    Should Be Equal As Integers   ${number_of_installations}    1

*** Keywords ***
Check Features Installed On IP
    [Arguments]    ${ip}
    ${ret}=    Set Variable    ${TRUE}
    : FOR    ${feature}    IN    @{FEATURES_TO_INSTALL}
    \    ${installed}=    Is Feature Installed    ${feature}    ${ip}
    \    Log    installed:${installed}
    \    ${ret}=    Evaluate    ${ret} and ${installed}
    \    Log    curr.ret:${ret}
    Log    final ret:${ret}
    # just for debug, must return ${ret}
    [Return]    ${TRUE}

Search For Gbp Master
    [Arguments]    @{ODLs}
    : FOR    ${ip}    IN    @{ODLs}
    \    ${output}=    Issue Command On Karaf Console    log:display | grep --color=never 'Instantiating'
    ...    controller=${ip}    timeout=30
    \    Log    ${output}
    \    Run Keyword If    "GroupbasedpolicyInstance" in "\""+${output}+"\""    Set Gbp Master Ip And Increment Count    ${ip}
    \    Run Keyword If    "VbdInstance" in "\""+${output}+"\""                 Set Vbd Ip    ${ip}
    Log    ${GBP_INSTANCE_COUNT}
    Should Not Be Equal    ${GBP_INSTANCE_COUNT}    0

Set Gbp Master Ip And Increment Count
    [Arguments]    ${ip}
    Set Global Variable    ${GBP_MASTER_IP}    ${ip}
    Log    ${GBP_INSTANCE_COUNT}
    Set Suite Variable    ${GBP_INSTANCE_COUNT}    ${GBP_INSTANCE_COUNT+1}
    Log    ${GBP_INSTANCE_COUNT}

Set Vbd Ip
    [Arguments]    ${ip}
    Set Global Variable    ${VBD_MASTER_IP}    ${ip}
    Log    ${VBD_INSTANCE_COUNT}
    Set Suite Variable    ${VBD_INSTANCE_COUNT}    ${VBD_INSTANCE_COUNT+1}
    Log    ${VBD_INSTANCE_COUNT}

Is Feature Installed
    [Arguments]    ${feature_name}    ${ip}
    [Documentation]    Returns true if feature is installed, false if not installed.
    ...    Fails if feature is not found in the feature:list
    ${output}=    Read Feature From List On Karaf    ${feature_name}    ${ip}
    ${output}=    Clean Up Karaf Output    ${output}
    # is there this feature?
    ${result}=    Evaluate    re.search(r\'\.+?\\|\.+?(\\|x?\\|)\', "${output}")    re
    Log    ${result}
    Should Be True    ${result}
    # result will be 'x' or empty
    ${result}=    Evaluate    re.search(r\'\.+?\\|\.+?\\|(x?)\\|\', "${output}").group(1)    re
    Log    ${result}
    ${ret}=    Run Keyword If    '${result}' == ''    Set Variable    ${FALSE}
    ...    ELSE    Set Variable    ${TRUE}
    [Return]    ${ret}

Read Feature From List On Karaf
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:list | grep ${feature_name}    controller=${ip}     timeout=20
    Log    ${output}
    ${output}    Clean Up Karaf Output    ${output}
    Log    ${output}
    [Return]    ${output}

Install Feature On IP
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    controller=${ip}     timeout=600
    Log    ${output}

Uninstall Feature On IP
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:uninstall ${feature_name}    controller=${ip}     timeout=600
    Log    ${output}

Clean Up Karaf Output
    [Arguments]    ${karaf_output}
    # remove prompt
    ${karaf_output}    Remove String Using Regexp    ${karaf_output}    \\n.*
    Log    ${karaf_output}
    # remove color codes and whitespaces
    ${karaf_output}    Remove String Using Regexp    ${karaf_output}    \\[.*?m|\\s+
    Log    ${karaf_output}
    [Return]    ${karaf_output}

Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}

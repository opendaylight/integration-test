 
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
${ODL_GBP_FEATURE_PREFIX}    odl-groupbasedpolicy-
@{FEATURES_TO_INSTALL}
...    ${ODL_GBP_FEATURE_PREFIX}ofoverlay

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
    \    Check Feature Not Installed    ${feature}    ${GBP_MASTER_IP}
    \    Install Feature On IP    ${feature}    ${GBP_MASTER_IP}
    \    Check Feature Installed    ${feature}    ${GBP_MASTER_IP}

*** Keywords ***
Search For Gbp Master
    [Arguments]    @{ODLs}
    : FOR    ${ip}    IN    @{ODLs}
    \    ${output}=    Issue Command On Karaf Console    log:display | grep --color=never 'Instantiating'    controller=${ip}
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
    ${VBD_IP}    Set Variable    ${ip}
    Set Global Variable    ${VBD_MASTER_IP}    ${ip}
    Log    ${VBD_INSTANCE_COUNT}
    Set Suite Variable    ${VBD_INSTANCE_COUNT}    ${VBD_INSTANCE_COUNT+1}
    Log    ${VBD_INSTANCE_COUNT}

Check Feature Not Installed
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:list | grep ${feature_name}    controller=${ip}     timeout=20
    Log    ${output}
    ${output}    Clear Karaf Output    ${output}
    Log    ${output}
    Should Match Regexp    "\""+${output}+"\""    ^${feature_name} +|[^|]+| {2,}

Check Feature Installed
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:list | grep ${feature_name}    controller=${ip}     timeout=20
    Log    ${output}
    ${output}    Clear Karaf Output    ${output}
    Log    ${output}
    Should Match Regexp    "\""+${output}+"\""    ^${feature_name} +|[^|]+| x

Install Feature On IP
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    controller=${ip}     timeout=60
    Log    ${output}

Clear Karaf Output
    [Arguments]    ${colorcoded_output}
    ${clean}    Remove String Using Regexp    ${colorcoded_output}    \\[.*?m
    [Return]    ${clean}

Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}

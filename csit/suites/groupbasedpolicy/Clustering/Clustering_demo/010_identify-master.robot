 
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
    \    Is Feature Installed    ${feature}    ${GBP_MASTER_IP}
#    \    Check Feature Not Installed    ${feature}    ${GBP_MASTER_IP}
    \    Install Feature On IP    ${feature}    ${GBP_MASTER_IP}
#    \    Check Feature Installed    ${feature}    ${GBP_MASTER_IP}
    \    Is Feature Installed    ${feature}    ${GBP_MASTER_IP}

*** Keywords ***
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
    ${output}=    Read Feature From List On Karaf    ${feature_name}    ${ip}
    ${output}=    Clear Karaf Output    ${output}
#    Should Match Regexp    "\""+${output}+"\""    ${feature_name} +\\|.+?\\|\\s(\\s|x)
#    Should Match Regexp    ${output}    ${feature_name}\\|.+?\\|x?\\|.*
    Should Match Regexp    ${output}    ${feature_name}\\|.+?\\|x?\\|
#    ${lines}=    Get Lines Matching Regexp    ${output}    ${feature_name}\\s+\\|.+?\\|\\s+x
    ${lines}=    Get Lines Matching Regexp    ${output}    ${feature_name}\\|.+?\\|x    partial_match=true
    Log    lines:${lines}
    Run Keyword If    '${lines}' == ''    Log    Not installed
    ...    ELSE    Log    Installed

Check Feature Not Installed
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Read Feature From List On Karaf    ${feature_name}    ${ip}
    Should Match Regexp    "\""+${output}+"\""    ${feature_name} +\\|[^\\|]+\\| {2,}

Check Feature Installed
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Read Feature From List On Karaf    ${feature_name}    ${ip}
    Should Match Regexp    "\""+${output}+"\""    ${feature_name} +\\|[^\\|]+\\| x

Read Feature From List On Karaf
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:list | grep ${feature_name}    controller=${ip}     timeout=20
    Log    ${output}
    ${output}    Clear Karaf Output    ${output}
    Log    ${output}
    [Return]    ${output}

Check Feature Installed On Any
    [Arguments]    ${feature_name}    @{ips}
    ${res}=    ${0}
    : FOR    ${ip}    IN    @{ips}
    \    Check Feature Installed    ${feature_name}    ${ip}

Install Feature On IP
    [Arguments]    ${feature_name}    ${ip}
    ${output}=    Issue Command On Karaf Console    feature:install ${feature_name}    controller=${ip}     timeout=600
    Log    ${output}

Clear Karaf Output
    [Arguments]    ${karaf_output}
    ${karaf_output}    Remove String Using Regexp    ${karaf_output}    \\n.*
    Log    ${karaf_output}
    ${karaf_output}    Remove String Using Regexp    ${karaf_output}    \\[.*?m|\\s+
    Log    ${karaf_output}
    [Return]    ${karaf_output}

Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}

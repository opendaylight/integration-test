*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Library           SSHLibrary    120 seconds
Resource          ../../../../libraries/KarafKeywords.robot

*** Variables ***
${GBP_INSTANCE_COUNT}    0
${VBD_INSTANCE_COUNT}    0
${OLD_MASTER}            0
${NEW_MASTER}            0

*** Test Cases ***
Identify New GBP Master Instance
    Log Many   ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Set Suite Variable    ${OLD_MASTER}    ${GBP_MASTER_IP}
    Wait Until Keyword Succeeds    10x    10 sec    Search For Gbp Master    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Should Be Equal As Integers   ${GBP_INSTANCE_COUNT}    1
    Should Not Be Equal    ${OLD_MASTER}    ${NEW_MASTER}
    Set Global Variable    ${GBP_MASTER_IP}    ${NEW_MASTER}
    Log    GBP ${GBP_MASTER_IP}, VBD ${VBD_MASTER_IP}

*** Keywords ***
Search For Gbp Master
    [Arguments]    @{ODLs}
    Set Suite Variable    ${GBP_INSTANCE_COUNT}    0
    : FOR    ${ip}    IN    @{ODLs}
    \    Continue For Loop If    '${ip}' == '${GBP_MASTER_IP}'
    \    ${output}=    Issue Command On Karaf Console    log:display | grep --color=never 'Instantiating'    controller=${ip}
    \    Log    ${output}
    \    Run Keyword If    "GroupbasedpolicyInstance" in "\""+${output}+"\""    Set Gbp Master Ip And Increment Count    ${ip}
    \    Run Keyword If    "VbdInstance" in "\""+${output}+"\""                 Set Vbd Ip    ${ip}
    Log    ${GBP_INSTANCE_COUNT}
    Should Not Be Equal    ${GBP_INSTANCE_COUNT}    0

Set Gbp Master Ip And Increment Count
    [Arguments]    ${ip}
    Set Suite Variable    ${NEW_MASTER}    ${ip}
    Log    ${GBP_INSTANCE_COUNT}
    ${NEW_COUNT}    Evaluate    ${GBP_INSTANCE_COUNT} + 1
    Set Suite Variable    ${GBP_INSTANCE_COUNT}    ${NEW_COUNT}
    Log    ${GBP_INSTANCE_COUNT}

Set Vbd Ip
    [Arguments]    ${ip}
    Set Global Variable    ${VBD_MASTER_IP}    ${ip}
    Log    ${VBD_INSTANCE_COUNT}
    ${NEW_COUNT}    Evaluate    ${VBD_INSTANCE_COUNT} + 1
    Set Suite Variable    ${VBD_INSTANCE_COUNT}    ${NEW_COUNT}
    Log    ${VBD_INSTANCE_COUNT}

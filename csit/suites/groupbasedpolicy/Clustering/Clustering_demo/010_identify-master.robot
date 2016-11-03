 
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
${GBP_INSTANCE_COUNT}    0
${VBD_INSTANCE_COUNT}    0

*** Test Cases ***
Identify GBP Master Instance
    Log Many   ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Wait Until Keyword Succeeds    10x    10 sec    Search For Gbp Master    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Should Be Equal As Integers   ${GBP_INSTANCE_COUNT}    1
    Log    GBP ${GBP_MASTER_IP}, VBD ${VBD_MASTER_IP}
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}

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

Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}

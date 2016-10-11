 
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
${VBD_IP}           ${EMPTY}

*** Test Cases ***
Identify GBP Master Instance
    Log Many   ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    : FOR    ${ip}    IN    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    \    ${output}=    Issue Command On Karaf Console    log:display | grep --color=never 'Instantiating'    controller=${ip}
    \    Log    ${output}
    \    ${output}    Remove String    ${output}    [
    \    Log    ${output}
    \    Run Keyword If    GroupbasedpolicyInstance in ${output}    Set Gbp Master Ip And Increment Count    ${ip}
    \    Run Keyword If    VbdInstance in ${output}                 Set Vbd Ip    ${ip}
    Should Be Equal    ${GBP_INSTANCE_COUNT}    1
    Log    GBP ${GBP_MASTER_IP}, VBD ${VBD_IP}
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}

*** Keywords ***
Set Gbp Master Ip And Increment Count
    [Arguments]    ${ip}
    Set Suite Variable    ${GBP_MASTER_IP}    ${ip}
    Set Variable    ${GBP_INSTANCE_COUNT}    ${GBP_INSTANCE_COUNT} + 1

Set Vbd Ip
    [Arguments]    ${ip}
    Set Variable    ${VBD_IP}    ${ip}

Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}

*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Teardown     Test Clean
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://127.0.0.1:8270/ExportTestLibrary    WITH NAME    ConnectionTestLibrary

*** Variables ***
${TESTED_NODE}    127.0.0.1

*** Test Cases ***
Remote Library Test
    [Documentation]    TODO
    ${resp}    ExportLibrary.Library Echo
    Should Not Be Equal    ${resp}    ${EMPTY}
    Log To Console    \n${resp}

Connectivity Test
    : FOR    ${num}    IN RANGE    0    2000
    \    ${ip}    Get Ip From Number    ${num}    2130771968

*** Keywords ***
Setup Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}
    [Documentation]    TODO
    ExportLibrary.Setup Nodes    ${TESTED_NODE}    64999
    ${address}    ExportLibrary.Get Source Address
    Add Connection    ${version}    listener    ${address}    64999    ${TESTED_NODE}    ${PASSWORD}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    ${address}    64999    ${TESTED_NODE}

    ${address}    ExportLibrary.Get Destination Address
    Add Connection    ${version}    speaker    ${address}    64999    ${TESTED_NODE}    ${PASSWORD}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    ${address}    64999    ${TESTED_NODE}


Test Clean
    [Arguments]
    [Documentation]    TODO
    ConnectionTestLibrary.Clean Library
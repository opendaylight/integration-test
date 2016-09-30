*** Settings ***
Documentation     Waiting for manager and switch connections.
Suite Setup       Start Connections
Suite Teardown    Close Connections
Library           SSHLibrary
Resource          ${CURDIR}/../../../../../libraries/GBP/ConnUtils.robot
Resource          ${CURDIR}/../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ${CURDIR}/../Variables.robot
Resource          ${CURDIR}/../Connections.robot

*** Testcases ***
Wait For Manager Connected on GBPSFC2
    Switch Connection    GPSFC2_CONNECTION
    Wait Until Keyword Succeeds    2 min    3s    Manager is Connected

Wait For Manager Connected on GBPSFC4
    Switch Connection    GPSFC4_CONNECTION
    Wait Until Keyword Succeeds    2 min    3s    Manager is Connected

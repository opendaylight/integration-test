*** Settings ***
Documentation     Waiting for manager and switch connections.
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Testcases ***

Wait For Manager Connected on GBPSFC2
    Switch Connection    GPSFC2_CONNECTION
    Wait Until Keyword Succeeds  2 min  3s    Manager is Connected

Wait For Manager Connected on GBPSFC4
    Switch Connection    GPSFC4_CONNECTION
    Wait Until Keyword Succeeds  2 min  3s    Manager is Connected

Wait For Manager and Switch Connected on GBPSFC1
    Switch Connection    GPSFC1_CONNECTION
    Wait Until Keyword Succeeds  2 min  3s    Manager and Switch Connected  sw1

Wait For Manager and Switch Connected on GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    Wait Until Keyword Succeeds  2 min  3s    Manager and Switch Connected  sw6

*** Settings ***
Documentation     Documentation     Waiting for flows to appear on switches.
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../Connections.robot
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Testcases ***

Wait For Flows on GBPSFC1
    Switch Connection    GPSFC1_CONNECTION
    Wait For Flows On Switch    ${GBPSFC1}    sw1

Wait For Flows on GBPSFC2
    Switch Connection    GPSFC2_CONNECTION
    Wait For Flows On Switch    ${GBPSFC2}    sw2

Wait For Flows on GBPSFC3
    Switch Connection    GPSFC3_CONNECTION
    Wait For Flows On Switch    ${GBPSFC3}    sw3

Wait For Flows on GBPSFC4
    Switch Connection    GPSFC4_CONNECTION
    Wait For Flows On Switch    ${GBPSFC4}    sw4

Wait For Flows on GBPSFC5
    Switch Connection    GPSFC5_CONNECTION
    Wait For Flows On Switch    ${GBPSFC5}    sw5

Wait For Flows on GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    Wait For Flows On Switch    ${GBPSFC6}    sw6


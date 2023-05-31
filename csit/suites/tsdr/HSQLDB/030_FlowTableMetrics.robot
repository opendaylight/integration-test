*** Settings ***
Documentation       Test suite for HSQLDB DataStore Flow Table Metrics Verification

Library             SSHLibrary
Library             Collections
Library             String
Library             ../../../libraries/Common.py
Resource            ../../../libraries/CompareStream.robot
Resource            ../../../libraries/KarafKeywords.robot
Resource            ../../../libraries/TsdrUtils.robot
Variables           ../../../variables/Variables.py

Suite Setup         Start Tsdr Suite
Suite Teardown      Stop Tsdr Suite


*** Variables ***
@{FLOWTABLE_METRICS}    ActiveFlows    PacketLookup    PacketMatch


*** Test Cases ***
Init Variables
    [Documentation]    Initialize ODL version specific variables
    Init Variables Master

Verification of TSDR FLOWTABLESTATS
    [Documentation]    Verify the TSDR FlowiTableStats
    Wait Until Keyword Succeeds
    ...    60s
    ...    1s
    ...    Verify the Metric is Collected?
    ...    ${TSDR_FLOWTABLE_STATS}| grep ActiveFlow | grep openflow:1
    ...    FLOWTABLESTATS
    ${output}=    Issue Command On Karaf Console
    ...    ${TSDR_FLOWTABLE_STATS}| grep openflow:1 | head
    ...    ${ODL_SYSTEM_IP}
    ...    ${KARAF_SHELL_PORT}
    ...    180
    FOR    ${list}    IN    @{FLOWTABLE_METRICS}
        Should Contain    ${output}    ${list}
    END


*** Keywords ***
Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Suite Variable    ${TSDR_FLOWTABLE_STATS}    tsdr:list FLOWTABLESTATS
*** Settings ***
Documentation     Test suite for HSQLDB DataStore Flow Metrics Verification
Suite Setup       Start Tsdr Suite
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{FLOW_METRICS}    PacketCount    ByteCount

*** Test Cases ***
Init Variables
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_VERSION}
    Run Keyword If    '${ODL_VERSION}' == 'stable-lithium'    Init Variables Lithium
    ...    ELSE    Init Variables Master

Verification of TSDR FlowMetrics
    [Documentation]    Verify the TSDR FLOWSTATS
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_FLOWSTATS}    PacketCount
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWSTATS}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{FLOW_METRICS}
    \    Should Contain    ${output}    ${list}

*** Keywords ***
Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Suite Variable    ${TSDR_FLOWSTATS}    tsdr:list FLOWSTATS

Init Variables Lithium
    [Documentation]    Sets variables specific to Lithium version
    Set Suite Variable    ${TSDR_FLOWSTATS}    tsdr:list FlowStats

*** Settings ***
Documentation     Test suite for H2 DataStore Flow Metrics Verification
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
${TSDR_FLOWSTATS}    tsdr:list FlowStats

*** Test Cases ***
Verification of TSDR FlowMetrics
    [Documentation]    Verify the TSDR FlowStats
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_FLOWSTATS}    PacketCount
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWSTATS}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{FLOW_METRICS}
    \    Should Contain    ${output}    ${list}

Verify FlowStats-Attributes on H2 Datastore using JDBC Client
    [Documentation]    Verify the PortStats,attributes on H2 Datastore using JDBC Client
    : FOR    ${list}    IN    @{FLOW_METRICS}
    \    ${output}=    Query Metrics on H2 Datastore    FLOWSTATS    ${list}
    \    Should Contain    ${output}    ${list}

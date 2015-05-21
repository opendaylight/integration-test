*** Settings ***
Documentation     Test suite for H2 DataStore Flow Table Metrics Verification
Suite Setup       Start Tsdr Suite
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.txt
Resource          ../../../libraries/TsdrUtils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
@{FLOWTABLE_METRICS}    ActiveFlows    PacketLookup    PacketMatch
${TSDR_FLOWTABLE_STATS}    tsdr:list FlowTableStats

*** Test Cases ***
Verification of TSDR FlowTableStats
    [Documentation]    Verify the TSDR FlowiTableStats
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_FLOWTABLE_STATS}| grep ActiveFlow    FLOWTABLESTATS
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWTABLE_STATS}| grep openflow:1 | head    ${CONTROLLER}    ${KARAF_SHELL_PORT}    180
    : FOR    ${list}    IN    @{FLOWTABLE_METRICS}
    \    Should Contain    ${output}    ${list}

Verify FlowTableStats-Attributes on H2 Datastore using JDBC Client
    [Documentation]    Verify the PortStats,attributes on H2 Datastore using JDBC Client
    : FOR    ${list}    IN    @{FLOWTABLE_METRICS}
    \    ${output}=    Query Metrics on H2 Datastore    FLOWTABLESTATS    ${list}
    \    Should Contain    ${output}    ${list}

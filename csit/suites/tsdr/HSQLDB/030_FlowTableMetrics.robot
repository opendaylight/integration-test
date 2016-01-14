*** Settings ***
Documentation     Test suite for HSQLDB DataStore Flow Table Metrics Verification
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
@{FLOWTABLE_METRICS}    ActiveFlows    PacketLookup    PacketMatch
${TSDR_FLOWTABLE_STATS}    tsdr:list FLOWTABLESTATS

*** Test Cases ***
Verification of TSDR FLOWTABLESTATS
    [Documentation]    Verify the TSDR FlowiTableStats
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_FLOWTABLE_STATS}| grep ActiveFlow    FLOWTABLESTATS
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWTABLE_STATS}| grep openflow:1 | head    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    180
    : FOR    ${list}    IN    @{FLOWTABLE_METRICS}
    \    Should Contain    ${output}    ${list}

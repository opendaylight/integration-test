*** Settings ***
Documentation     Test suite for Hbase DataStore Flow Stats Verification
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
@{FLOW_METRICS}    PacketCount    ByteCount
${TSDR_FLOWSTATS}    tsdr:list FlowStats

*** Test Cases ***
Verification of TSDR FlowMetrics
    [Documentation]    Verify the TSDR FlowStats
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_FLOWSTATS}    PacketCount
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWSTATS}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{FLOW_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of FlowMetrics-PacketCount on HBase Client
    [Documentation]    Verify the FlowStats-Packetcount on both Karaf console and Hbase client
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWSTATS}    | grep PacketCount | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    ${Line1}=    Get Line    ${output}    0
    Should Contain    ${Line1}    PacketCount
    ${q1}=    Generate HBase Query    FlowMetrics    PacketCount_openflow:1_0
    ${out}=    Query the Data from HBaseClient    ${q1}
    Comment    ${output}=    Get Metrics Value    ${Line1}
    Should Match Regexp    ${out}    (?mui)PacketCount_openflow

Verification of FlowMetrics-BytesCount on HBase Client
    [Documentation]    Verify the FlowStats-ByteCount on both Karaf Console and Hbase Client
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWSTATS}    | grep ByteCount | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    ${Line1}=    Get Line    ${output}    0
    Should Contain    ${Line1}    ByteCount
    ${q1}=    Generate HBase Query    FlowMetrics    ByteCount_openflow:1_0
    ${out}=    Query the Data from HBaseClient    ${q1}
    Should Match Regexp    ${out}    (?mui)ByteCount_openflow

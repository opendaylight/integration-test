*** Settings ***
Documentation     Test suite for Hbase DataStore Flow Stats Verification
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
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_FLOWSTATS}    PacketCount
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWSTATS}
    Close Karaf Console
    : FOR    ${list}    IN    @{FLOW_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of FlowMetrics-PacketCount on HBase Client
    [Documentation]    Verify the FlowStats-Packetcount on both Karaf console and Hbase client
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWSTATS}    | grep PacketCount | head
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}
    Close Karaf Console
    ${Line1}=    Get Line    ${output}    0
    Should Contain    ${Line1}    PacketCount
    ${q1}=    Generate HBase Query    FlowMetrics    PacketCount_openflow:1_0
    ${out}=    Query the Data from HBaseClient    ${q1}
    Comment    ${output}=    Get Metrics Value    ${Line1}
    Should Match Regexp    ${out}    (?mui)PacketCount_openflow

Verification of FlowMetrics-BytesCount on HBase Client
    [Documentation]    Verify the FlowStats-ByteCount on both Karaf Console and Hbase Client
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWSTATS}    | grep ByteCount | head
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}
    Close Karaf Console
    ${Line1}=    Get Line    ${output}    0
    Should Contain    ${Line1}    ByteCount
    ${q1}=    Generate HBase Query    FlowMetrics    ByteCount_openflow:1_0
    ${out}=    Query the Data from HBaseClient    ${q1}
    Should Match Regexp    ${out}    (?mui)ByteCount_openflow

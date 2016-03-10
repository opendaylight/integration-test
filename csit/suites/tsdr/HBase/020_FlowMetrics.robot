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

*** Test Cases ***
Init Variables
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_VERSION}
    Run Keyword If    '${ODL_VERSION}' == 'stable-lithium'    Init Variables Lithium
    ...    ELSE    Init Variables Master

Verification of TSDR FlowMetrics
    [Documentation]    Verify the TSDR FlowStats
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_FLOWSTATS}    PacketCount
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWSTATS}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{FLOW_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of FlowMetrics-PacketCount on HBase Client
    [Documentation]    Verify the FlowStats-Packetcount on both Karaf console and Hbase client
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWSTATS}    | grep PacketCount | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    90
    ${Line1}=    Get Line    ${output}    0
    Should Contain    ${Line1}    PacketCount
    Verify the Metrics Attributes on Hbase Client    PacketCount    ${node_connector}    ${flowstats}

Verification of FlowMetrics-BytesCount on HBase Client
    [Documentation]    Verify the FlowStats-ByteCount on both Karaf Console and Hbase Client
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWSTATS}    | grep ByteCount | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    90
    ${Line1}=    Get Line    ${output}    0
    Should Contain    ${Line1}    ByteCount
    Verify the Metrics Attributes on Hbase Client    ByteCount    ${node_connector}    ${flowstats}

*** Keywords ***
Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Suite Variable    ${TSDR_FLOWSTATS}    tsdr:list FLOWSTATS
    set Suite Variable    ${node_connector}    Node:openflow:1,Table:0
    set suite Variable    ${flowstats}    FLOWSTATS

Init Variables Lithium
    [Documentation]    Sets variables specific to Lithium version
    Set Suite Variable    ${TSDR_FLOWSTATS}    tsdr:list FlowStats
    set Suite Variable    ${node_connector}    openflow:1_0
    set suite Variable    ${flowstats}    FlowMetrics

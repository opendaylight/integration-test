*** Settings ***
Documentation     Test suite for Hbase DataStore Flow Table Stats Verification
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
${TSDR_FLOWTABLE_STATS}    tsdr:list FLOWTABLESTATS

*** Test Cases ***
Verification of TSDR FlowTableMetrics
    [Documentation]    Verify the TSDR FlowTableMetrics
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_FLOWTABLE_STATS}    MN
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWTABLE_STATS}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    30
    Should Contain    ${output}    MN

Verification of FlowTableMetrics on Karaf Console
    [Documentation]    Verify the FlowTableMetrics has been updated thru tsdr:list command on karaf console
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWTABLE_STATS}    | grep ActiveFlows | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    90
    Should Contain    ${output}    ActiveFlows

Verification of FlowTableMetrics-ActiveFlows on HBase Client
    [Documentation]    Verify the FlowTableMetrics has been updated on HBase Datastore
    Verify the Metrics Attributes on Hbase Client    ActiveFlows    Node:openflow:1,Table:0    FLOWTABLESTATS

Verification of FlowTableMetrics-PacketMatch on HBase Client
    [Documentation]    Verify the FlowTableMetrics has been updated on HBase Datastore
    Verify the Metrics Attributes on Hbase Client    PacketMatch    Node:openflow:1,Table:0    FLOWTABLESTATS


Verification of FlowTableMetrics-PacketLookup on HBase Client
    [Documentation]    Verify the FlowTableMetrics has been updated on HBase Datastore
    Verify the Metrics Attributes on Hbase Client    PacketLookup    Node:openflow:1,Table:0    FLOWTABLESTATS


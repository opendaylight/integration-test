*** Settings ***
Documentation     Test suite for Hbase DataStore Flow Table Stats Verification
Suite Setup       Start Tsdr Suite
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
${TSDR_FLOWTABLE_STATS}    tsdr:list FlowTableStats

*** Test Cases ***
Verification of TSDR FlowTableMetrics
    [Documentation]    Verify the TSDR FlowTableMetrics
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_FLOWTABLE_STATS}    MetricName
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWTABLE_STATS}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    Should Contain    ${output}    MetricName

Verification of FlowTableMetrics on Karaf Console
    [Documentation]    Verify the FlowTableMetrics has been updated thru tsdr:list command on karaf console
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWTABLE_STATS}    | grep ActiveFlows | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    Should Contain    ${output}    ActiveFlows

Verification of FlowTableMetrics-ActiveFlows on HBase Client
    [Documentation]    Verify the FlowTableMetrics has been updated on HBase Datastore
    ${query}=    Generate HBase Query    FlowTableMetrics    ActiveFlows_openflow:1_0
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)ActiveFlows_openflow

Verification of FlowTableMetrics-PacketMatch on HBase Client
    [Documentation]    Verify the FlowTableMetrics has been updated on HBase Datastore
    ${query}=    Generate HBase Query    FlowTableMetrics    PacketMatch_openflow:1_0_
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)PacketMatch_openflow

Verification of FlowTableMetrics-PacketLookup on HBase Client
    [Documentation]    Verify the FlowTableMetrics has been updated on HBase Datastore
    ${query}=    Generate HBase Query    FlowTableMetrics    PacketLookup_openflow:1_0_
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)PacketLookup_openfl

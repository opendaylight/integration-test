*** Settings ***
Documentation     Test suite for Hbase DataStore Queue Stats Verification
Suite Setup       Run Keywords    Start Tsdr Suite    Configuration of Queue on Switch
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{QUEUE_METRICS}    TransmittedPackets    TransmittedBytes    TransmissionErrors
${TSDR_QUEUESTATS}    tsdr:list QueueStats

*** Test Cases ***
Verify the Queue Metrics attributes exist thru Karaf console
    [Documentation]    Verify the QueueMetrics attributes exist on Karaf Console
    Wait Until Keyword Succeeds    180s    1s    Verify the Metric is Collected?    ${TSDR_QUEUESTATS}    Transmitted
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    ${output}=    Issue Command On Karaf Console    ${TSDR_QUEUESTATS}
    Close Karaf Console
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of QueueMetrics-TransmittedPackets on Karaf Console
    [Documentation]    Verify the QueueMetrics has been updated thru tsdr:list command on karaf console
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_QUEUESTATS}    | grep TransmittedPackets | head
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}
    Close Karaf Console
    Should Contain    ${output}    TransmittedPackets

Verification of QueueMetrics-TransmittedPackets on HBase Client
    [Documentation]    Verify the QueueMetrics has been updated on HBase Datastore
    ${query}=    Generate HBase Query    QueueMetrics    TransmittedPackets_openflow:1
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)TransmittedPackets

Verification of QueueMetrics-TransmittedBytes on HBase Client
    [Documentation]    Verify the QueueMetrics has been updated on HBase Datastore
    ${query}=    Generate HBase Query    QueueMetrics    TransmittedBytes_openflow:1
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)TransmittedBytes

Verification of QueueMetrics-TransmissionErrors on HBase Client
    [Documentation]    Verify the QueueMetrics has been updated on HBase Datastore
    ${query}=    Generate HBase Query    QueueMetrics    TransmissionErrors_openflow:1
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)TransmissionErrors

*** Keyword ***
Configuration of Queue on Switch
    [Documentation]    Queue configuration on openvswitch
    Configure the Queue on Switch    s2-eth2

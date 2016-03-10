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

*** Test Cases ***
Init Variables
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_VERSION}
    Run Keyword If    '${ODL_VERSION}' == 'stable-lithium'    Init Variables Lithium
    ...    ELSE    Init Variables Master

Verify the Queue Metrics attributes exist thru Karaf console
    [Documentation]    Verify the QueueMetrics attributes exist on Karaf Console
    Wait Until Keyword Succeeds    180s    1s    Verify the Metric is Collected?    ${TSDR_QUEUESTATS}    Transmitted
    ${output}=    Issue Command On Karaf Console    ${TSDR_QUEUESTATS}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    90
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of QueueMetrics-TransmittedPackets on Karaf Console
    [Documentation]    Verify the QueueMetrics has been updated thru tsdr:list command on karaf console
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_QUEUESTATS}    | grep TransmittedPackets | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    90
    Should Contain    ${output}    TransmittedPackets

Verification of QueueMetrics-TransmittedPackets on HBase Client
    [Documentation]    Verify the QueueMetrics has been updated on HBase Datastore
    Verify the Metrics Attributes on Hbase Client    TransmittedPackets    ${node_connector}    ${queuestats}

Verification of QueueMetrics-TransmittedBytes on HBase Client
    [Documentation]    Verify the QueueMetrics has been updated on HBase Datastore
    Verify the Metrics Attributes on Hbase Client    TransmittedBytes    ${node_connector}    ${queuestats}

Verification of QueueMetrics-TransmissionErrors on HBase Client
    [Documentation]    Verify the QueueMetrics has been updated on HBase Datastore
    Verify the Metrics Attributes on Hbase Client    TransmissionErrors    ${node_connector}    ${queuestats}

*** Keywords ***
Configuration of Queue on Switch
    [Documentation]    Queue configuration on openvswitch
    Configure the Queue on Switch    s2-eth2

Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Suite Variable    ${TSDR_QUEUESTATS}    tsdr:list QUEUESTATS
    set Suite Variable    ${node_connector}    Node:openflow:2
    set suite Variable    ${queuestats}    QUEUESTATS

Init Variables Lithium
    [Documentation]    Sets variables specific to Lithium version
    Set Suite Variable    ${TSDR_QUEUESTATS}    tsdr:list QueueStats
    set Suite Variable    ${node_connector}    openflow:2
    set suite Variable    ${queuestats}    QueueMetrics

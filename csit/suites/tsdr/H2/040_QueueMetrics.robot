*** Settings ***
Documentation     Test suite for H2 DataStore Queue Metrics Verification
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
${TSDR_QUEUE_STATS}    tsdr:list QueueStats
@{CMD_LIST}       FlowGroupStats    FlowMeterStats    FlowStats    FlowTableStats    PortStats    QueueStats

*** Test Cases ***
Verify the Queue Stats attributes exist thru Karaf console
    [Documentation]    Verify the QueueMetrics attributes exist on Karaf Console
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_QUEUE_STATS}    Transmitted
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    ${output}=    Issue Command On Karaf Console    ${TSDR_QUEUE_STATS}
    Close Karaf Console
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    Should Contain    ${output}    ${list}

Verify QueueStats-Attributes on H2 Datastore using JDBC Client
    [Documentation]    Verify the QueueStats,attributes on H2 Datastore using JDBC Client
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    ${output}=    Query Metrics on H2 Datastore    QUEUESTATS    ${list}
    \    Should Contain    ${output}    ${list}

Verify tsdr:purgeall command
    [Documentation]    Verify the tsdr:purgeall command
    Issue Command On Karaf Console    tsdr:purgeall
    : FOR    ${list}    IN    @{CMD_LIST}
    \    ${out}=    Issue Command On Karaf Console    tsdr:list ${list}
    \    Should Contain    ${out}    no data of this category
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    ${out}=    Query Metrics on H2 Datastore    QUEUESTATS    ${list}
    \    Should not Contain    ${out}    ${list}

*** Keyword ***
Configuration of Queue on Switch
    [Documentation]    Queue configuration on openvswitch
    Configure the Queue on Switch    s2-eth2

*** Settings ***
Documentation     Test suite for H2 DataStore Queue Metrics Verification
Suite Setup       Run Keywords    Start Tsdr Suite    Configuration of Queue on Switch
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.txt
Resource          ../../../libraries/TsdrUtils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
@{QUEUE_METRICS}    TransmittedPackets    TransmittedBytes    TransmissionErrors
${TSDR_QUEUE_STATS}    tsdr:list QueueStats
@{CMD_LIST}       FlowGroupStats    FlowMeterStats    FlowStats    FlowTableStats    PortStats    QueueStats

*** Test Cases ***
Verify the Queue Stats attributes exist thru Karaf console
    [Documentation]    Verify the QueueMetrics attributes exist on Karaf Console
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_QUEUE_STATS}    Transmitted
    ${output}=    Issue Command On Karaf Console    ${TSDR_QUEUE_STATS}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    Should Contain    ${output}    ${list}

Verify QueueStats-Attributes on H2 Datastore using JDBC Client
    [Documentation]    Verify the QueueStats,attributes on H2 Datastore using JDBC Client
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    ${output}=    Query Metrics on H2 Datastore    QUEUESTATS    ${list}
    \    Should Contain    ${output}    ${list}

Verify tsdr:purgeall command
    [Documentation]    Verify the tsdr:purgeall command
    Issue Command On Karaf Console    tsdr:purgeall    ${CONTROLLER}    ${KARAF_SHELL_PORT}
    : FOR    ${list}    IN    @{CMD_LIST}
    \    ${out}=    Issue Command On Karaf Console    ${list}    ${CONTROLLER}    ${KARAF_SHELL_PORT}
    \    Should Contain    ${out}    no data of this category
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    ${out}=    Query Metrics on H2 Datastore    QUEUESTATS    ${list}
    \    Should not Contain    ${out}    ${list}

Uninstall all TSDR H2 Feature
    [Documentation]    UnInstall all TSDR HBase Features
    Uninstall a Feature    odl-tsdr-H2-persistence
    Verify Feature Is Not Installed    odl-tsdr-H2-persistence
    Uninstall a Feature    odl-tsdr-all
    Verify Feature Is Not Installed    odl-tsdr-all
    Uninstall a Feature    odl-tsdr-core
    Verify Feature Is Not Installed    odl-tsdr-core

Verification TSDR Command shouldnot exist in help
    [Documentation]    Verify the TSDR List command on help
    ${output}=    Issue Command On Karaf Console    tsdr\t    ${CONTROLLER}    ${KARAF_SHELL_PORT}
    Should not Contain    ${output}    tsdr:list

*** Keyword ***
Configuration of Queue on Switch
    [Documentation]    Queue configuration on openvswitch
    Configure the Queue on Switch    s2-eth2

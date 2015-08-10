*** Settings ***
Documentation     Test suite for H2 DataStore InterfaceMetrics Verification
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
@{INTERFACE_METRICS}    TransmittedPackets    TransmittedBytes    TransmitErrors    TransmitDrops    ReceivedPackets    ReceivedBytes    ReceiveOverRunError
...               ReceiveFrameError    ReceiveErrors    ReceiveDrops    ReceiveCrcError    CollisionCount
@{CATEGORY}       FlowGroupStats    FlowMeterStats    FlowStats    FlowTableStats    PortStats    QueueStats
${TSDR_PORTSTATS}    tsdr:list PortStats

*** Test Cases ***
Verification of TSDR H2 Feature Installation
    [Documentation]    Install and Verify the TSDR H2 Datastore and JDBC
    Install a Feature    jdbc    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    Verify Feature Is Installed    jdbc
    COMMENT    Install a Feature    odl-tsdr-all    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    Verify Feature Is Installed    odl-tsdr-all
    Verify Feature Is Installed    odl-tsdr-H2-persistence
    Verify Feature Is Installed    odl-tsdr-core
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    log:display | grep "TSDR H2"    TSDR H2

Verification TSDR Command is exist in Help
    [Documentation]    Verify the TSDR List command on Help
    ${output}=    Issue Command On Karaf Console    tsdr\t
    Should Contain    ${output}    tsdr:list
    Should Contain    ${output}    tsdr:purgeall
    ${output}=    Issue Command On Karaf Console    tsdr:list\t\t
    : FOR    ${list}    IN    @{CATEGORY}
    \    Should Contain    ${output}    ${list}
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_PORTSTATS}    openflow

Verify PortStats On Karaf console
    [Documentation]    Verify the InterfaceMetrics(PortStats),attributes using ${TSDR_PORTSTATS}
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    ${tsdr_cmd}=    Concatenate the String    ${TSDR_PORTSTATS}    | grep ${list} | head
    \    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    \    Should Contain    ${output}    ${list}

Verify PortStats-Attributes on H2 Datastore using JDBC Client
    [Documentation]    Verify the PortStats,attributes on H2 Datastore using JDBC Client
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    ${output}=    Query Metrics on H2 Datastore    PORTSTATS    ${list}
    \    Should Contain    ${output}    ${list}

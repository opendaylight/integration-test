*** Settings ***
Documentation     Test suite for Hbase DataStore PortStats Verification
Suite Setup       Run Keywords    Start Tsdr Suite    Initialize the HBase for TSDR
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.txt
Resource          ../../../libraries/TsdrUtils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
@{INTERFACE_METRICS}    TransmittedPackets    TransmittedBytes    TransmitErrors    TransmitDrops    ReceivedPackets    ReceivedBytes    ReceiveOverRunError
...               ReceiveFrameError    ReceiveErrors    ReceiveDrops    ReceiveCrcError    CollisionCount
@{CATEGORY}       FlowGroupStats    FlowMeterStats    FlowStats    FlowTableStats    PortStats    QueueStats
${TSDR_PORTSTATS}    tsdr:list PortStats

*** Test Cases ***
Verification of TSDR HBase Feature Installation
    [Documentation]    Install and Verify the TSDR HBase Features
    COMMENT    Install a Feature    odl-tsdr-hbase    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    Verify Feature Is Installed    odl-tsdr-hbase
    Verify Feature Is Installed    odl-tsdr-hbase-persistence
    Verify Feature Is Installed    odl-hbaseclient

Verification TSDR Command is exist in Help
    [Documentation]    Verify the TSDR List command on Help
    ${output}=    Issue Command On Karaf Console    tsdr\t
    Should Contain    ${output}    tsdr:list
    ${output}=    Issue Command On Karaf Console    tsdr:list\t\t
    : FOR    ${list}    IN    @{CATEGORY}
    \    Should Contain    ${output}    ${list}
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_PORTSTATS}    openflow

Verification of TSDR PortStats
    [Documentation]    Verify the TSDR InterfaceMetrics
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    ${tsdr_cmd}=    Concatenate the String    ${TSDR_PORTSTATS}    | grep ${list} | head
    \    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    \    Should Contain    ${output}    ${list}

Verification of InterfaceMetrics-Attributes on HBase Client
    [Documentation]    Verify the InterfaceMetrics has been updated on HBase Datastore
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    Verify the Metrics Attributes on Hbase Client    ${list}    openflow:1_1    InterfaceMetrics

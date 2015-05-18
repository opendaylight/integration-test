*** Settings ***
Documentation     Test suite for Hbase DataStore Queue Stats Verification
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
${TSDR_QUEUESTATS}    tsdr:list QueueStats

*** Test Cases ***
Verify the Queue Metrics attributes exist thru Karaf console
    [Documentation]    Verify the QueueMetrics attributes exist on Karaf Console
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_QUEUESTATS}    Transmitted
    ${output}=    Issue Command On Karaf Console    ${TSDR_QUEUESTATS}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of QueueMetrics-TransmittedPackets on Karaf Console
    [Documentation]    Verify the QueueMetrics has been updated thru tsdr:list command on karaf console
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_QUEUESTATS}    | grep TransmittedPackets | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
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

Uninstall all TSDR HBase Feature
    [Documentation]    UnInstall all TSDR HBase Features
    Uninstall a Feature    odl-tsdr-hbase-persistence
    Verify Feature Is Not Installed    odl-tsdr-hbase-persistence
    Uninstall a Feature    odl-hbaseclient
    Verify Feature Is Not Installed    odl-hbaseclient
    Uninstall a Feature    odl-tsdr-core
    Verify Feature Is Not Installed    odl-tsdr-core
    Uninstall a Feature    odl-tsdr-hbase
    Verify Feature Is Not Installed    odl-tsdr-hbase

Verification TSDR Command shouldnot exist in help
    [Documentation]    Verify the TSDR List command on help
    ${output}=    Issue Command On Karaf Console    tsdr\t    ${CONTROLLER}    ${KARAF_SHELL_PORT}
    Should not Contain    ${output}    tsdr:list

*** Keyword ***
Configuration of Queue on Switch
    [Documentation]    Queue configuration on openvswitch
    Configure the Queue on Switch    s2-eth2

*** Settings ***
Documentation     Test suite for HSQLDB DataStore InterfaceMetrics Verification
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

*** Test Cases ***
Init Variables
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_VERSION}
    Run Keyword If    '${ODL_VERSION}' == 'stable-lithium'    Init Variables Lithium
    ...    ELSE    Init Variables Master

Verification of TSDR HSQLDB Feature Installation
    [Documentation]    Install and Verify the TSDR HSQLDB Datastore and JDBC
    COMMENT    Install a Feature    odl-tsdr-hsqldb    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    COMMENT    Install a Feature    odl-tsdr-openflow-statistics-collector    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    Verify Feature Is Installed    ${HSQLDB_INSTALL}
    Verify Feature Is Installed    odl-tsdr-core

Verification TSDR Command exists in Help
    [Documentation]    Verify the TSDR List command on Help
    ${output}=    Issue Command On Karaf Console    tsdr\t
    Should Contain    ${output}    tsdr:list
    ${output}=    Issue Command On Karaf Console    tsdr:list\t\t
    : FOR    ${list}    IN    @{CATEGORY}
    \    Should Contain    ${output}    ${list}
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_PORTSTATS}    openflow

Verify PortStats On Karaf console
    [Documentation]    Verify the InterfaceMetrics(PortStats),attributes using ${TSDR_PORTSTATS}
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    ${tsdr_cmd}=    Concatenate the String    ${TSDR_PORTSTATS}    | grep ${list} | head
    \    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    30
    \    Should Contain    ${output}    ${list}

*** Keywords ***
Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Suite Variable    @{CATEGORY}    FLOWGROUPSTATS    FLOWMETERSTATS    FLOWSTATS    FLOWTABLESTATS    PORTSTATS
    ...    QUEUESTATS
    Set Suite Variable    ${TSDR_PORTSTATS}    tsdr:list PORTSTATS
    Set Suite Variable    ${HSQLDB_INSTALL}    odl-tsdr-hsqldb

Init Variables Lithium
    [Documentation]    Sets variables specific to Lithium version
    Set Suite Variable    @{CATEGORY}    FlowStats    FlowTableStats    PortStats    QueueStats
    Set Suite Variable    ${TSDR_PORTSTATS}    tsdr:list PortStats
    Set Suite Variable    ${HSQLDB_INSTALL}    odl-tsdr-HSQLDB

*** Settings ***
Documentation     Test suite for Hbase DataStore PortStats Verification
Suite Setup       Initialize the Tsdr Suite
Suite Teardown    Stop Tsdr Suite
Metadata          https://bugs.opendaylight.org/show_bug.cgi?id=5068    ${EMPTY}
Library           SSHLibrary
Library           Collections
Library           String
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{INTERFACE_METRICS}    TransmittedPackets    TransmittedBytes    TransmitErrors    TransmitDrops    ReceivedPackets    ReceivedBytes    ReceiveOverRunError
...               ReceiveFrameError    ReceiveErrors    ReceiveDrops    ReceiveCrcError    CollisionCount
@{CATEGORY}       FLOWGROUPSTATS    FLOWMETERSTATS    FLOWSTATS    FLOWTABLESTATS    PORTSTATS    QUEUESTATS
${TSDR_PORTSTATS}    tsdr:list PORTSTATS
${CONFIG_INTERVAL}    /restconf/config/tsdr-openflow-statistics-collector:TSDROSCConfig
${OPER_INTERVAL}    /restconf/operations/tsdr-openflow-statistics-collector:setPollingInterval
&{HEADERS_QUERY}    Content-Type=application/json    Content-Type=application/json

*** Test Cases ***
Verification of TSDR HBase Feature Installation
    [Documentation]    Install and Verify the TSDR HBase Features
    COMMENT    Install a Feature    odl-tsdr-hbase    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    Verify Feature Is Installed    odl-tsdr-hbase
    Verify Feature Is Installed    odl-hbaseclient

Verification TSDR Command is exist in Help
    [Documentation]    Verify the TSDR List command on Help
    ${output}=    Issue Command On Karaf Console    tsdr\t
    Should Contain    ${output}    tsdr:list
    ${output}=    Issue Command On Karaf Console    tsdr:list\t\t
    : FOR    ${list}    IN    @{CATEGORY}
    \    Should Contain    ${output}    ${list}
    Wait Until Keyword Succeeds    620s    1s    Verify the Metric is Collected?    ${TSDR_PORTSTATS}    openflow

Verification of TSDR PortStats
    [Documentation]    Verify the TSDR InterfaceMetrics
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    ${tsdr_cmd}=    Concatenate the String    ${TSDR_PORTSTATS}    | grep ${list} | head
    \    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    30
    \    Should Contain    ${output}    ${list}

Verification of InterfaceMetrics-Attributes on HBase Client
    [Documentation]    Verify the InterfaceMetrics has been updated on HBase Datastore
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    Verify the Metrics Attributes on Hbase Client    ${list}    Node:openflow:1,NodeConnector:1    PORTSTATS

Verify Configuration Interval-change
    [Documentation]    Verify the TSDR Collection configuration changes
    Wait Until Keyword Succeeds    5x    3 sec    Post TSDR Configuration Interval    15000
    Wait Until Keyword Succeeds    5x    3 sec    Verify TSDR Configuration Interval    15000
    Wait Until Keyword Succeeds    5x    3 sec    Post TSDR Configuration Interval    20000
    Wait Until Keyword Succeeds    5x    3 sec    Verify TSDR Configuration Interval    20000
    Wait Until Keyword Succeeds    5x    3 sec    Post TSDR Configuration Interval    15000
    Wait Until Keyword Succeeds    5x    3 sec    Verify TSDR Configuration Interval    15000
    [Teardown]    Report_Failure_Due_To_Bug    5068

*** Keywords ***
Initialize the Tsdr Suite
    COMMENT    Initialize the HBase for TSDR
    Start Tsdr Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_QUERY}

Verify TSDR Configuration Interval
    [Arguments]    ${interval}
    [Documentation]    Verify Configuration interval of TSDR Collection
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_INTERVAL}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${interval}

Post TSDR Configuration Interval
    [Arguments]    ${interval}
    [Documentation]    Configuration TSDR collection interval ${interval}
    ${p1}    Create Dictionary    interval=${interval}
    ${p2}    Create Dictionary    input=${p1}
    ${p2_json}=    json.dumps    ${p2}
    ${resp}    RequestsLibrary.Post Request    session    ${OPER_INTERVAL}    data=${p2_json}
    Should Be Equal As Strings    ${resp.status_code}    200

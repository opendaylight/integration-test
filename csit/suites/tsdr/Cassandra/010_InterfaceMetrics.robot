*** Settings ***
Documentation     Test suite for Cassandra DataStore PortStats Verification
COMMENT    Suite Setup       Initialize the Tsdr Suite
Suite Teardown    Stop Tsdr Suite
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
${root_path}    flow-capable-node-connector-statistics
@{xpath}    ${root_path}/packets/transmitted    ${root_path}/bytes/transmitted    ${root_path}/transmit-errors    ${root_path}/transmit-drops    ${root_path}/packets/received    ${root_path}/bytes/received    ${root_path}/receive-over-run-error
...                ${root_path}/receive-frame-error    ${root_path}/receive-errors    ${root_path}/receive-drops    ${root_path}/receive-crc-error    ${root_path}/collision-count
@{CATEGORY}       FlowStats    FlowTableStats    PortStats    QueueStats
${TSDR_PORTSTATS}    tsdr:list PortStats
${CONFIG_INTERVAL}    /restconf/config/tsdr-openflow-statistics-collector:TSDRDCConfig
${OPER_INTERVAL}    /restconf/operations/tsdr-openflow-statistics-collector:setPollingInterval
${QUERY_HEAD}    /restconf/operational/opendaylight-inventory:nodes/node
${metric_path}     metric_path
${metric_val}     metric_val
@{xml_list}
@{tsdr_list}

*** Test Cases ***
Verification of TSDR Cassandra Feature Installation
    [Documentation]    Install and Verify the TSDR Cassandra Features
    COMMENT    Install a Feature    odl-tsdr-cassandra-all    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    Wait Until Keyword Succeeds    24x    10 sec    Check Karaf Log Has Messages    tsdr.openflow
    Verify Feature Is Installed    odl-tsdr-cassandra
    Verify Feature Is Installed    odl-tsdr-openflow-statistics-collector
    Start Tsdr Suite
    Ping All Hosts
    Wait Until Keyword Succeeds    5x    30 sec    Check Metric path    24\\d+|25\\d+
    Wait Until Keyword Succeeds    5x    30 sec    Check Metric val     \\d{5}

Storing Statistics from Openflow REST

    [Documentation]    Store openflow PortStats metrics using REST.
    : FOR    ${item}    IN    @{xpath}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:1/node-connector/openflow:1:1    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:1/node-connector/openflow:1:2    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:1/node-connector/openflow:1:LOCAL    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:2/node-connector/openflow:2:1    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:2/node-connector/openflow:2:2    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:2/node-connector/openflow:2:3    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:2/node-connector/openflow:2:LOCAL    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:3/node-connector/openflow:3:1    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:3/node-connector/openflow:3:2    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    \    ${ret_val}=    Get Stats XML    ${QUERY_HEAD}/openflow:3/node-connector/openflow:3:LOCAL    ${item}
    \    Append To List    ${xml_list}    ${ret_val}
    \    ${ret_val}=    Set Variable    -1
    Log List    ${xml_list}



Verification of InterfaceMetrics-Attributes on Cassandra Client
    [Documentation]    Verify the InterfaceMetrics has been updated on Cassandra Data Store
    Copy TSDR tables
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:1*DC=PORTSTATS*MN=${list}*RK=Node:openflow:1,NodeConnector:openflow:1:1*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:1*DC=PORTSTATS*MN=${list}*RK=Node:openflow:1,NodeConnector:openflow:1:2*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:1*DC=PORTSTATS*MN=${list}*RK=Node:openflow:1,NodeConnector:openflow:1:LOCAL*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:2*DC=PORTSTATS*MN=${list}*RK=Node:openflow:2,NodeConnector:openflow:2:1*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:2*DC=PORTSTATS*MN=${list}*RK=Node:openflow:2,NodeConnector:openflow:2:2*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:2*DC=PORTSTATS*MN=${list}*RK=Node:openflow:2,NodeConnector:openflow:2:3*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:2*DC=PORTSTATS*MN=${list}*RK=Node:openflow:2,NodeConnector:openflow:2:LOCAL*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:3*DC=PORTSTATS*MN=${list}*RK=Node:openflow:3,NodeConnector:openflow:3:1*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:3*DC=PORTSTATS*MN=${list}*RK=Node:openflow:3,NodeConnector:openflow:3:2*
    \    Append To List    ${tsdr_list}    ${ret_val1}
    \    ${ret_val1}=    Extract From DB Table    *NID=openflow:3*DC=PORTSTATS*MN=${list}*RK=Node:openflow:3,NodeConnector:openflow:3:LOCAL*
    \    Append To List    ${tsdr_list}    ${ret_val1}

Comparing Mertics

    [Documentation]    Compare openflow Interface metrics between data collected from openflow Plugin and TSDR
    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${xml_list}    ${tsdr_list}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}



Verify Configuration Interval-change
    [Documentation]    Verify the TSDR Collection configuration changes
    ${session}=    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Verify TSDR Configuration Interval    180
    Post TSDR Configuration Interval    200
    Verify TSDR Configuration Interval    200
    Post TSDR Configuration Interval    180
    Verify TSDR Configuration Interval    180
    Delete All Sessions

*** Keywords ***
Initialize the Tsdr Suite
    COMMENT    Initialize Cassandra Tables
Verify TSDR Configuration Interval
    [Arguments]    ${interval}
    [Documentation]    Verify Configuration interval of TSDR Collection
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_INTERVAL}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${interval}

Post TSDR Configuration Interval
    [Arguments]    ${interval}
    [Documentation]    Configuration TSDR collection interval ${interval}
    ${p1}    Create Dictionary    interval    ${interval}
    ${p2}    Create Dictionary    input    ${p1}
    ${post_data}    Create Dictionary    setPollingInterval    ${p2}
    Log    ${post_data}
    ${resp}    RequestsLibrary.Post    session    ${OPER_INTERVAL}    ${post_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Extract From DB Table
    [Arguments]    ${pattern}
    [Documentation]    Extract from metricpath table and return the value
    ${ret_val1}=    Set Variable    -100
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    ${pattern}
    [Return]    ${ret_val1}




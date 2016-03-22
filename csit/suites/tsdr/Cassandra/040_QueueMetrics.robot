*** Settings ***
Documentation     Test suite for Cassandra DataStore Queue Stats Verification
Suite Setup       Initialize Cassandra Tables Metricval
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
${QUERY_HEAD}     ${OPERATIONAL_NODES_API}/node
${query_head1}    ${QUERY_HEAD}/openflow:2/node-connector/openflow:2:2/queue/
@{tsdr_q0}
@{tsdr_q2}
@{tsdr_q1}
${transmittedpackets}    flow-capable-node-connector-queue-statistics/transmitted-packets
${transmittedbytes}    flow-capable-node-connector-queue-statistics/transmitted-bytes
${transmittederrors}    flow-capable-node-connector-queue-statistics/transmission-errors
@{openflow_q0}
@{openflow_q2}
@{openflow_q1}

*** Test Cases ***
Verification of TSDR Cassandra Feature Installation
    [Documentation]    Install and Verify the TSDR Cassandra Features
    COMMENT    Install a Feature    odl-tsdr-cassandra-all    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    Verify Feature Is Installed    odl-tsdr-cassandra
    COMMENT    Verify Feature Is Installed    odl-tsdr-cassandra-persistence
    Verify Feature Is Installed    odl-tsdr-openflow-statistics-collector
    Start Tsdr Suite
    Configuration of Queue on Switch
    Ping All Hosts
    Wait Until Keyword Succeeds    5x    30 sec    Check Metric val    \\d{5}

Getting all Tables from Openflow Plugin
    [Documentation]    Getting Queue Stats from openflow plugin
    ${ret}=    Get Stats XML    ${query_head1}0/    ${transmittederrors}
    Append To List    ${openflow_q0}    ${ret}
    ${ret}=    Get Stats XML    ${query_head1}0/    ${transmittedpackets}
    Append To List    ${openflow_q0}    ${ret}
    ${ret}=    Get Stats XML    ${query_head1}0/    ${transmittedbytes}
    Append To List    ${openflow_q0}    ${ret}
    Set Suite Variable    @{openflow_q0}
    ${ret}=    Get Stats XML    ${query_head1}1/    ${transmittederrors}
    Append To List    ${openflow_q1}    ${ret}
    ${ret}=    Get Stats XML    ${query_head1}1/    ${transmittedpackets}
    Append To List    ${openflow_q1}    ${ret}
    ${ret}=    Get Stats XML    ${query_head1}1/    ${transmittedbytes}
    Append To List    ${openflow_q1}    ${ret}
    Set Suite Variable    @{openflow_q1}
    ${ret}=    Get Stats XML    ${query_head1}2/    ${transmittederrors}
    Append To List    ${openflow_q2}    ${ret}
    ${ret}=    Get Stats XML    ${query_head1}2/    ${transmittedpackets}
    Append To List    ${openflow_q2}    ${ret}
    ${ret}=    Get Stats XML    ${query_head1}2/    ${transmittedbytes}
    Append To List    ${openflow_q2}    ${ret}
    Set Suite Variable    @{openflow_q2}

Verification of FlowStats-Attributes on Cassandra Data Store
    [Documentation]    Verify the InterfaceMetrics has been updated on Cassandra Data Store
    Copy TSDR tables
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmissionErrors | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:0
    Append To List    ${tsdr_q0}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmittedPackets | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:0
    Append To List    ${tsdr_q0}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmittedBytes | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:0
    Append To List    ${tsdr_q0}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmissionErrors | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:1
    Append To List    ${tsdr_q1}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmittedPackets | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:1
    Append To List    ${tsdr_q1}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmittedBytes | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:1
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmissionErrors | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:2
    Append To List    ${tsdr_q2}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmittedPackets | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:2
    Append To List    ${tsdr_q2}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    grep NID=openflow:2 | grep DC=QUEUESTATS | grep MN=TransmittedBytes | grep RK=Node:openflow:2,NodeConnector:openflow:2:2,Queue:2
    Append To List    ${tsdr_q2}    ${ret_val1}

Comparing Queue Metrics
    [Documentation]    Comparing Queue metrics between Cassandra and OF plugin
    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_q0}    ${tsdr_q0}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20
    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_q1}    ${tsdr_q1}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20
    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_q2}    ${tsdr_q2}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20

*** Keyword ***
Configuration of Queue on Switch
    [Documentation]    Queue configuration on openvswitch
    Configure the Queue on Switch    s2-eth2

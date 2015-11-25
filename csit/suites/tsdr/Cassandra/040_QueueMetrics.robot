*** Settings ***
Documentation     Test suite for Cassandra DataStore Queue Stats Verification
Suite Setup           Initialize Cassandra Tables Metricval 
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
${query_head}    /restconf/operational/opendaylight-inventory:nodes/node/openflow:2/node-connector/openflow:2:2/queue/
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
    Install a Feature    odl-tsdr-cassandra-all    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    Wait Until Keyword Succeeds    24x    10 sec    Verify Log    tsdr.openflow
    Verify Feature Is Installed    odl-tsdr-cassandra
    Verify Feature Is Installed    odl-tsdr-cassandra-persistence
    Verify Feature Is Installed    odl-tsdr-openflow-statistics-collector
    Start Tsdr Suite
    Configuration of Queue on Switch
    Ping All Hosts
    Wait Until Keyword Succeeds    5x    30 sec    Check Metric path    24\\d+|25\\d+|26\\d+|27\\d+
    Wait Until Keyword Succeeds    5x    30 sec    Check Metric val     \\d{5}

Getting all Tables from Openflow Plugin

    ${ret}=    Get Stats XML    ${query_head}0/   ${transmittederrors}
    Append To List    ${openflow_q0}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}0/    ${transmittedpackets}
    Append To List    ${openflow_q0}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}0/    ${transmittedbytes}
    Append To List    ${openflow_q0}    ${ret}

    Set Suite Variable  @{openflow_q0}


    ${ret}=    Get Stats XML    ${query_head}1/   ${transmittederrors}
    Append To List    ${openflow_q1}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}1/    ${transmittedpackets}
    Append To List    ${openflow_q1}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}1/    ${transmittedbytes}
    Append To List    ${openflow_q1}    ${ret}

    Set Suite Variable  @{openflow_q1}


    ${ret}=    Get Stats XML    ${query_head}2/   ${transmittederrors}
    Append To List    ${openflow_q2}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}2/    ${transmittedpackets}
    Append To List    ${openflow_q2}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}2/    ${transmittedbytes}
    Append To List    ${openflow_q2}    ${ret}

    Set Suite Variable  @{openflow_q2}


Verification of FlowStats-Attributes on Cassandra Data Store
    [Documentation]    Verify the InterfaceMetrics has been updated on Cassandra Data Store
    Copy TSDR tables
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmissionErrors.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_0
    Append To List    ${tsdr_q0}    ${ret_val1}    
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmittedPackets.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_0
    Append To List    ${tsdr_q0}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmittedBytes.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_0
    Append To List    ${tsdr_q0}    ${ret_val1}



    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmissionErrors.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_1
    Append To List    ${tsdr_q1}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmittedPackets.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_1
    Append To List    ${tsdr_q1}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmittedBytes.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_1
    Append To List    ${tsdr_q1}    ${ret_val1}




    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmissionErrors.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_2
    Append To List    ${tsdr_q2}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmittedPackets.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_2
    Append To List    ${tsdr_q2}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    QUEUESTATS.TransmittedBytes.openflow:2.Node_openflow:2.NodeConnector_openflow:2:2.Queue_2
    Append To List    ${tsdr_q2}    ${ret_val1}


Comparing Flow Table Metrics

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

*** Settings ***
Documentation     Test suite for Cassandra DataStore Flow Stats Verification
Suite Setup       Initialize the Tsdr Suite
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***

@{FLOW_METRICS}    PacketCount    ByteCount
${TSDR_FLOWSTATS}    tsdr:list FlowStats
${query_head}    /restconf/operational/opendaylight-inventory:nodes/node/
${packet_count}    flow/flow-statistics/packet-count
${byte_count}    flow/flow-statistics/byte-count
@{tsdr_op1}
@{tsdr_op2}
@{tsdr_op3}
@{tsdr_op1_pc}
@{tsdr_op2_pc}
@{tsdr_op3_pc}
@{tsdr_op1_bc}
@{tsdr_op2_bc}
@{tsdr_op3_bc}


*** Test Cases ***

Verification of TSDR Cassandra Feature Installation
    [Documentation]    Install and Verify the TSDR Cassandra Features
    Install a Feature    odl-tsdr-cassandra-all    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    Wait Until Keyword Succeeds    24x    10 sec    Verify Log    tsdr.openflow
    Verify Feature Is Installed    odl-tsdr-cassandra
    Verify Feature Is Installed    odl-tsdr-cassandra-persistence
    Verify Feature Is Installed    odl-tsdr-openflow-statistics-collector
    Start Tsdr Suite
    Ping All Hosts
    Wait Until Keyword Succeeds    5x    30 sec    Check Metric path    24\\d+|25\\d+
    Wait Until Keyword Succeeds    5x    30 sec    Check Metric val     \\d{5}


Getting all Tables from Openflow Plugin

    @{openflow_1}=    Return all XML matches    ${query_head}openflow:1/table/0/    flow/id
    @{openflow_2}=    Return all XML matches    ${query_head}openflow:2/table/0/    flow/id
    @{openflow_3}=    Return all XML matches    ${query_head}openflow:3/table/0/    flow/id

    Set Suite Variable 	@{openflow_1}
    Set Suite Variable  @{openflow_2}
    Set Suite Variable  @{openflow_3}

    @{openflow_1_packetcount}=    Return all XML matches    ${query_head}openflow:1/table/0/    ${packet_count}
    @{openflow_2_packetcount}=    Return all XML matches    ${query_head}openflow:2/table/0/    ${packet_count}
    @{openflow_3_packetcount}=    Return all XML matches    ${query_head}openflow:3/table/0/    ${packet_count}

    Set Suite Variable  @{openflow_1_packetcount}
    Set Suite Variable  @{openflow_2_packetcount}
    Set Suite Variable  @{openflow_3_packetcount}


    @{openflow_1_bytecount}=    Return all XML matches    ${query_head}openflow:1/table/0/    ${byte_count}
    @{openflow_2_bytecount}=    Return all XML matches    ${query_head}openflow:2/table/0/    ${byte_count}
    @{openflow_3_bytecount}=    Return all XML matches    ${query_head}openflow:3/table/0/    ${byte_count}

    Set Suite Variable  @{openflow_1_bytecount}
    Set Suite Variable  @{openflow_2_bytecount}
    Set Suite Variable  @{openflow_3_bytecount}


Verification of FlowStats-Attributes on Cassandra Data Store
    [Documentation]    Verify the InterfaceMetrics has been updated on Cassandra Data Store
    Copy TSDR tables
    : FOR    ${flow}    IN    @{openflow_1}
    \   ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    FLOWSTATS.PacketCount.openflow:1.Node_openflow:1.Table_0.Flow_${flow}
    \   Append To List    ${tsdr_op1_pc}    ${ret_val1}
   
    : FOR    ${flow}    IN    @{openflow_2}
    \   ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    FLOWSTATS.PacketCount.openflow:2.Node_openflow:2.Table_0.Flow_${flow}
    \   Append To List    ${tsdr_op2_pc}    ${ret_val1}

    : FOR    ${flow}    IN    @{openflow_3}
    \   ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    FLOWSTATS.PacketCount.openflow:3.Node_openflow:3.Table_0.Flow_${flow}
    \   Append To List    ${tsdr_op3_pc}    ${ret_val1}

    : FOR    ${flow}    IN    @{openflow_1}
    \   ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    FLOWSTATS.ByteCount.openflow:1.Node_openflow:1.Table_0.Flow_${flow}
    \   Append To List    ${tsdr_op1_bc}    ${ret_val1}

    : FOR    ${flow}    IN    @{openflow_2}
    \   ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    FLOWSTATS.ByteCount.openflow:2.Node_openflow:2.Table_0.Flow_${flow}
    \   Append To List    ${tsdr_op2_bc}    ${ret_val1}

    : FOR    ${flow}    IN    @{openflow_3}
    \   ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client    FLOWSTATS.ByteCount.openflow:3.Node_openflow:3.Table_0.Flow_${flow}
    \   Append To List    ${tsdr_op3_bc}    ${ret_val1}

    Set Suite Variable  @{tsdr_op1_pc}
    Set Suite Variable  @{tsdr_op2_pc}
    Set Suite Variable  @{tsdr_op3_pc}
    Set Suite Variable  @{tsdr_op1_bc}
    Set Suite Variable  @{tsdr_op2_bc}
    Set Suite Variable  @{tsdr_op3_bc}


Comparing Packet Count Metrics

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_1_packetcount}    ${tsdr_op1_pc}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_2_packetcount}    ${tsdr_op2_pc}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_3_packetcount}    ${tsdr_op3_pc}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20



Comparing Byte Count Metrics

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_1_bytecount}    ${tsdr_op1_bc}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_2_bytecount}    ${tsdr_op2_bc}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_3_bytecount}    ${tsdr_op3_bc}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    20




*** Keywords ***
Initialize the Tsdr Suite
    COMMENT    Initialize the Cassandra for TSDR
    Initialize Cassandra Tables Metricval


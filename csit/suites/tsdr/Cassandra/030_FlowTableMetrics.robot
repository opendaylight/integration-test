*** Settings ***
Documentation     Test suite for Cassandra DataStore Flow Table Stats Verification
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
${TSDR_FLOWTABLE_STATS}    tsdr:list FlowTableStats
${query_head}    /restconf/operational/opendaylight-inventory:nodes/node/
@{tsdr_pl}
@{tsdr_af}
@{tsdr_pm}
${packetlookup}    flow-table-statistics/packets-looked-up
${activeflows}    flow-table-statistics/active-flows
${packetmatched}    flow-table-statistics/packets-matched
@{openflow_packetlookup}
@{openflow_activeflows}
@{openflow_packetmatched}

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

    ${ret}=    Get Stats XML    ${query_head}openflow:1/table/0/    ${packetlookup}
    Append To List    ${openflow_packetlookup}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}openflow:2/table/0/    ${packetlookup}
    Append To List    ${openflow_packetlookup}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}openflow:3/table/0/    ${packetlookup}
    Append To List    ${openflow_packetlookup}    ${ret}

    Set Suite Variable  @{openflow_packetlookup}


    ${ret}=    Get Stats XML    ${query_head}openflow:1/table/0/    ${activeflows}
    Append To List    ${openflow_activeflows}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}openflow:2/table/0/    ${activeflows}
    Append To List    ${openflow_activeflows}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}openflow:3/table/0/    ${activeflows}
    Append To List    ${openflow_activeflows}    ${ret}

    Set Suite Variable  @{openflow_activeflows}

    ${ret}=    Get Stats XML    ${query_head}openflow:1/table/0/    ${packetmatched}
    Append To List    ${openflow_packetmatched}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}openflow:2/table/0/    ${packetmatched}
    Append To List    ${openflow_packetmatched}    ${ret}
    ${ret}=    Get Stats XML    ${query_head}openflow:3/table/0/    ${packetmatched}
    Append To List    ${openflow_packetmatched}    ${ret}

    Set Suite Variable  @{openflow_packetmatched}




Verification of FlowStats-Attributes on Cassandra Data Store
    [Documentation]    Verify the InterfaceMetrics has been updated on Cassandra Data Store
    Copy TSDR tables
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.PacketLookup.openflow:1.Node_openflow:1.Table_0
    Append To List    ${tsdr_pl}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.PacketLookup.openflow:2.Node_openflow:2.Table_0
    Append To List    ${tsdr_pl}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.PacketLookup.openflow:3.Node_openflow:3.Table_0
    Append To List    ${tsdr_pl}    ${ret_val1}



    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.ActiveFlows.openflow:1.Node_openflow:1.Table_0
    Append To List    ${tsdr_af}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.ActiveFlows.openflow:2.Node_openflow:2.Table_0
    Append To List    ${tsdr_af}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.ActiveFlows.openflow:3.Node_openflow:3.Table_0
    Append To List    ${tsdr_af}    ${ret_val1}


    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.PacketMatch.openflow:1.Node_openflow:1.Table_0
    Append To List    ${tsdr_pm}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.PacketMatch.openflow:2.Node_openflow:2.Table_0
    Append To List    ${tsdr_pm}    ${ret_val1}
    ${ret_val1}=    Verify the Metrics Attributes on Cassandra Client     FLOWTABLESTATS.PacketMatch.openflow:3.Node_openflow:3.Table_0
    Append To List    ${tsdr_pm}    ${ret_val1}




Comparing Flow Table Metrics

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_packetlookup}    ${tsdr_pl}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    5

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_activeflows}    ${tsdr_af}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    5

    : FOR    ${xml_val}    ${tsdr_val}    IN ZIP    ${openflow_packetmatched}    ${tsdr_pm}
    \    Compare Tsdr XML Metrics    ${xml_val}    ${tsdr_val}    5



*** Keywords ***
Initialize the Tsdr Suite
    COMMENT    Initialize the Cassandra for TSDR
    Initialize Cassandra Tables Metricval


*** Settings ***
Documentation     Test suite for ElasticSearch DataStore PortStats Verification
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
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
Verification of TSDR ElasticSearch Feature Installation
    [Documentation]    Install and Verify the Elastic Search Features
    COMMENT    Install a Feature    odl-tsdr-elasticsearch    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    Install a Feature    odl-tsdr-elasticsearch    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    Install a Feature    odl-tsdr-openflow-statistics-collector    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    260
    COMMENT    Wait Until Keyword Succeeds    24x    10 sec    Check Karaf Log Has Messages    tsdr.openflow
    Verify Feature Is Installed    odl-tsdr-elasticsearch
    Verify Feature Is Installed    odl-tsdr-openflow-statistics-collector
    Start Tsdr Suite
    Ping All Hosts
    Clear Elasticsearch Datastore
    Wait Until Keyword Succeeds    30x    1 sec    Check Available values from Elasticsearch    FLOWTABLESTATS    4571

Comparing Flow Table Metrics
    [Documentation]    Comparing Flow table values between Elasticsearch and openflow plugin.
    Getting all Tables from Openflow Plugin
    Getting all Tables from ElasticSearch datastore
    Should Be Equal As Strings    ${tsdr_pl}    ${openflow_packetlookup}
    Should Be Equal As Strings    ${tsdr_af}    ${openflow_activeflows}
    Should Be Equal As Strings    ${tsdr_pm}    ${openflow_packetmatched}

*** Keywords ***
Getting all Tables from Openflow Plugin
    [Documentation]    Getting Flow Table Stats Values from Openflow plugin
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/    ${packetlookup}
    Append To List    ${openflow_packetlookup}    ${ret}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:2/table/0/    ${packetlookup}
    Append To List    ${openflow_packetlookup}    ${ret}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:3/table/0/    ${packetlookup}
    Append To List    ${openflow_packetlookup}    ${ret}
    Set Suite Variable    @{openflow_packetlookup}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/    ${activeflows}
    Append To List    ${openflow_activeflows}    ${ret}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:2/table/0/    ${activeflows}
    Append To List    ${openflow_activeflows}    ${ret}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:3/table/0/    ${activeflows}
    Append To List    ${openflow_activeflows}    ${ret}
    Set Suite Variable    @{openflow_activeflows}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/    ${packetmatched}
    Append To List    ${openflow_packetmatched}    ${ret}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:2/table/0/    ${packetmatched}
    Append To List    ${openflow_packetmatched}    ${ret}
    ${ret}=    Get Stats XML    ${OPERATIONAL_NODES_API}/node/openflow:3/table/0/    ${packetmatched}
    Append To List    ${openflow_packetmatched}    ${ret}
    Set Suite Variable    @{openflow_packetmatched}

Getting all Tables from ElasticSearch datastore
    [Documentation]    Getting Flow Table Stats Values from ELK plugin
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    PacketLookup    openflow:1    openflow:1
    Append To List    ${tsdr_pl}    ${ret}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    PacketLookup    openflow:2    openflow:2
    Append To List    ${tsdr_pl}    ${ret}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    PacketLookup    openflow:3    openflow:3
    Append To List    ${tsdr_pl}    ${ret}
    Set Suite Variable    @{tsdr_pl}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    ActiveFlows    openflow:1    openflow:1
    Append To List    ${tsdr_af}    ${ret}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    ActiveFlows    openflow:2    openflow:2
    Append To List    ${tsdr_af}    ${ret}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    ActiveFlows    openflow:3    openflow:3
    Append To List    ${tsdr_af}    ${ret}
    Set Suite Variable    @{tsdr_af}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    PacketMatch    openflow:1    openflow:1
    Append To List    ${tsdr_pm}    ${ret}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    PacketMatch    openflow:2    openflow:2
    Append To List    ${tsdr_pm}    ${ret}
    ${ret}=    Retrieve Value From Elasticsearch    FLOWTABLESTATS    PacketMatch    openflow:3    openflow:3
    Append To List    ${tsdr_pm}    ${ret}
    Set Suite Variable    @{tsdr_pm}

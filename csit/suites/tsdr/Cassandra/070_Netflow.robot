*** Settings ***
Documentation     Test suite for Cassandra DataStore Netflow Stats Verification
Suite Setup       Initialize Netflow
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${IP_1}           10.0.0.1
${IP_2}           10.0.0.2
${NODE_ID}        127.0.0.1
${engine_type}    11
${engine_id}      11
${nexthop}        0
${port}           0
${prot}           1
${int1}           1
${int2}           2
${version}        5

*** Test Cases ***
Verifying TSDR Data Store For Netflow Entries
    [Documentation]    Verify the Cassandra Data store to check if Netflow data is stored.
    Copy TSDR tables    val_table=metriclog
    ${metric_log}=    Verify the Metrics Syslog on Cassandra Client    grep DC=NETFLOW
    Should Contain    ${metric_log}    srcAddr=${IP_2}
    ${netflow}=    Create Temporary Key Info    srcAddr=${IP_2}    val_table=metriclog
    Should Contain    ${netflow}    srcAddr=${IP_2}
    Should Contain    ${netflow}    dstAddr=${IP_1}
    Should Contain    ${netflow}    srcPort=${port}
    Should Contain    ${netflow}    protocol=${prot}
    Should Contain    ${netflow}    nextHop=${nexthop}
    Should Contain    ${netflow}    engine_type
    Should Contain    ${netflow}    engine_id
    Should Contain    ${netflow}    input=${int2}
    Should Contain    ${netflow}    output=${int1}
    Should Contain    ${netflow}    sysUpTime
    Should Contain    ${netflow}    flow_sequence
    Should Contain    ${netflow}    unix_nsecs
    Should Contain    ${netflow}    dPkts
    Should Contain    ${netflow}    tcpFlags
    Should Contain    ${netflow}    samplingInterval=0
    Should Contain    ${netflow}    dstAS=0
    Should Contain    ${netflow}    srcAS=0
    Should Contain    ${netflow}    dstMask=0
    Should Contain    ${netflow}    srcMask=0
    ${netflow}=    Create Temporary Key Info    srcAddr=${IP_1}    val_table=metriclog
    Should Contain    ${netflow}    srcAddr=${IP_1}
    Should Contain    ${netflow}    dstAddr=${IP_2}
    Should Contain    ${netflow}    dstPort=${port}
    Should Contain    ${netflow}    protocol=${prot}
    Should Contain    ${netflow}    nextHop=${nexthop}
    Should Contain    ${netflow}    engine_type
    Should Contain    ${netflow}    engine_id
    Should Contain    ${netflow}    input=${int1}
    Should Contain    ${netflow}    output=${int2}
    Should Contain    ${netflow}    sysUpTime
    Should Contain    ${netflow}    flow_sequence
    Should Contain    ${netflow}    unix_nsecs
    Should Contain    ${netflow}    dPkts
    Should Contain    ${netflow}    tcpFlags
    Should Contain    ${netflow}    samplingInterval=0
    Should Contain    ${netflow}    dstAS=0
    Should Contain    ${netflow}    srcAS=0
    Should Contain    ${netflow}    dstMask=0
    Should Contain    ${netflow}    srcMask=0

*** Keywords ***
Initialize Netflow
    [Documentation]    Initialize Netflow setup and start collecting the netflow samples.
    Verify Feature Is Installed    odl-tsdr-cassandra
    Bringup Netflow
    Initialize Cassandra Tables Metricval    val_table=metriclog
    Wait Until Keyword Succeeds    36x    5 sec    Ping Pair Hosts Cassandra    \\d{2}

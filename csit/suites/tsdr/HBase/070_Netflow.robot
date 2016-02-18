*** Settings ***
Documentation     Test suite for Hbase DataStore Netflow Stats Verification
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
${nextHop}        0
${port}           0
${protocol}       1
${int1}           1
${int2}           2
${version}        5

*** Test Cases ***
Verification of Full Record Text for Netflow Dumps
    [Documentation]    Verify the Netflow Record Text Hbase client
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1' , LIMIT => 10, FILTER => "ValueFilter( =, 'regexstring:srcAddr=${IP_2}' )" }
    Should Contain    ${out}    srcAddr=${IP_2}
    Should Contain    ${out}    dstAddr=${IP_1}
    Should Contain    ${out}    srcPort=${port}
    Should Contain    ${out}    protocol=${protocol}
    Should Contain    ${out}    nextHop=${nexthop}
    Should Contain    ${out}    engine_type
    Should Contain    ${out}    engine_id
    Should Contain    ${out}    input=${int2}
    Should Contain    ${out}    output=${int1}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1' , LIMIT => 10, FILTER => "ValueFilter( =, 'regexstring:srcAddr=${IP_1}' )" }
    Should Contain    ${out}    srcAddr=${IP_1}
    Should Contain    ${out}    dstAddr=${IP_2}
    Should Contain    ${out}    dstPort=${port}
    Should Contain    ${out}    protocol=${protocol}
    Should Contain    ${out}    nextHop=${nexthop}
    Should Contain    ${out}    engine_type
    Should Contain    ${out}    engine_id
    Should Contain    ${out}    input=${int1}
    Should Contain    ${out}    output=${int2}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW'
    Should Contain    ${out}    sysUpTime
    Should Contain    ${out}    flow_sequence
    Should Contain    ${out}    unix_nsecs
    Should Contain    ${out}    dPkts
    Should Contain    ${out}    tcpFlags
    Should Contain    ${out}    dstAS=0
    Should Contain    ${out}    srcAS=0
    Should Contain    ${out}    dstMask=0
    Should Contain    ${out}    srcMask=0

Verification of Metric Record for Netflow Dumps
    [Documentation]    Verify the Netflow Metric Record Hbase client
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:dstAddr' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${IP_1}' )" }
    Should Contain    ${out}    value=${IP_1}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:srcAddr' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${IP_1}' )" }
    Should Contain    ${out}    value=${IP_1}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:dstAddr' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${IP_2}' )" }
    Should Contain    ${out}    value=${IP_2}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:srcAddr' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${IP_2}' )" }
    Should Contain    ${out}    value=${IP_2}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:input' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${int1}' )" }
    Should Contain    ${out}    value=${int1}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:output' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${int2}' )" }
    Should Contain    ${out}    value=${int2}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:input' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${int2}' )" }
    Should Contain    ${out}    value=${int2}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:output' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${int1}' )" }
    Should Contain    ${out}    value=${int1}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:flowDuration' , LIMIT => 10}
    Should Contain    ${out}    flowDuration
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:nextHop' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${nextHop}' )" }
    Should Contain    ${out}    value=${nextHop}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:version' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${version}' )" }
    Should Contain    ${out}    value=${version}
    ${out}=    Query the Data from HBaseClient    scan 'NETFLOW',{ COLUMNS => 'c1:protocol' , LIMIT => 10, FILTER => "ValueFilter( =, 'binaryprefix:${protocol}' )" }
    Should Contain    ${out}    value=${protocol}

*** Keywords ***
Initialize Netflow
    [Documentation]    Initialize Netflow setup and start collecting the netflow samples.
    Query the Data from HBaseClient    truncate 'NETFLOW'
    Bringup Netflow
    Wait Until Keyword Succeeds    36x    5 sec    Ping Pair Hosts Hbase    \\d{2} row

*** Settings ***
Documentation     Test suite for HSQLDB DataStore NetFlow Stats Verification
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
Verification of Full Record Text for Netflow Dumps
    [Documentation]    Verify the Netflow Record Text Hbase client
    ${out}=    Issue Command On Karaf Console    tsdr:list NETFLOW | grep srcAddr=${IP_2}
    Should Contain    ${out}    srcPort=${port}
    Should Contain    ${out}    srcAddr=${IP_2}
    Should Contain    ${out}    dstAddr=${IP_1}
    Should Contain    ${out}    srcPort=${port}
    Should Contain    ${out}    protocol=${prot}
    Should Contain    ${out}    nextHop=${nexthop}
    Should Contain    ${out}    engine_type
    Should Contain    ${out}    engine_id
    Should Contain    ${out}    input=${int2}
    Should Contain    ${out}    output=${int1}
    ${out}=    Issue Command On Karaf Console    tsdr:list NETFLOW | grep srcAddr=${IP_1}
    Should Contain    ${out}    srcAddr=${IP_1}
    Should Contain    ${out}    dstAddr=${IP_2}
    Should Contain    ${out}    dstPort=${port}
    Should Contain    ${out}    protocol=${prot}
    Should Contain    ${out}    nextHop=${nexthop}
    Should Contain    ${out}    engine_type
    Should Contain    ${out}    engine_id
    Should Contain    ${out}    input=${int1}
    Should Contain    ${out}    output=${int2}
    Should Contain    ${out}    sysUpTime
    Should Contain    ${out}    flow_sequence
    Should Contain    ${out}    unix_nsecs
    Should Contain    ${out}    dPkts
    Should Contain    ${out}    dOctets
    Should Contain    ${out}    tcpFlags
    Should Contain    ${out}    dstAS=0
    Should Contain    ${out}    srcAS=0
    Should Contain    ${out}    dstMask=0
    Should Contain    ${out}    srcMask=0

*** Keywords ***
Initialize Netflow
    [Documentation]    Initialize Mininet topology and check if netflow data is getting collected
    Bringup Netflow
    Wait Until Keyword Succeeds    36x    5 sec    Ping Pair Hosts HSQLDB    2\\d+

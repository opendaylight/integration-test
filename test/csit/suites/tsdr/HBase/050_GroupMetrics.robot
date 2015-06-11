*** Settings ***
Documentation     Test suite for Hbase DataStore FlowGroup Stats Verification
Suite Setup       Run Keywords    Start TSDR suite with CPqD Switch    Configuration of FlowGroup on Switch
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.txt
Resource          ../../../libraries/TsdrUtils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
@{FLOWGROUP_METRICS}    ByteCount    PacketCount    RefCount
${TSDR_FLOWGROUPSTATS}    tsdr:list FlowGroupStats
@{FLOWGROUP_HEADER}    MetricName    MetricValue    MetricCategory    MetricDetails

*** Test Cases ***
Verify the FlowGroup Stats attributes exist thru Karaf console
    [Documentation]    Verify the FlowGroupStats attributes exist on Karaf Console
    Wait Until Keyword Succeeds    180s    1s    Verify the Metric is Collected?    ${TSDR_FLOWGROUPSTATS}    ByteCount
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWGROUPSTATS}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{FLOWGROUP_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of FlowGroupStats-ByteCount on Karaf Console
    [Documentation]    Verify the FlowGroupStats has been updated thru tsdr:list command on karaf console
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWGROUPSTATS}    | grep ByteCount | head
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    Should Contain    ${output}    ByteCount
    Should Contain    ${output}    FlowGroupStats
    Should not Contain    ${output}    null
    : FOR    ${list}    IN    @{FLOWGROUP_HEADER}
    \    Should Contain    ${output}    ${list}

Verification of FlowGroupStats-ByteCount on HBase Client
    [Documentation]    Verify the FlowGroupStats has been updated on HBase Datastore
    ${query}=    Generate HBase Query    GroupMetrics    ByteCount_openflow:1
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)ByteCount

Verification of FlowGroupStats-PacketCount on HBase Client
    [Documentation]    Verify the FlowGroupStats has been updated on HBase Datastore
    ${query}=    Generate HBase Query    GroupMetrics    PacketCount_openflow:1
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)PacketCount

Verification of FlowGroupStats-RefCount on HBase Client
    [Documentation]    Verify the FlowGroupStats has been updated on HBase Datastore
    ${query}=    Generate HBase Query    GroupMetrics    RefCount_openflow:1
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)RefCount

*** Keyword ***
Start TSDR suite with CPqD Switch
    Start Tsdr Suite    user

Configuration of FlowGroup on Switch
    [Documentation]    FlowGroup configuration on CPqD
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s1 group-mod cmd=add,group=1,type=all
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s1 flow-mod table=0,cmd=add eth_type=0x800,eth_src=00:01:02:03:04:05 apply:group=1
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s1 ping 10
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s2 ping 10

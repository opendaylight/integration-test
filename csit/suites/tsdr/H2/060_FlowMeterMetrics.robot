*** Settings ***
Documentation     Test suite for H2 DataStore FlowMeter Stats Verification
Suite Setup       Run Keywords    Start TSDR suite with CPqD Switch    Configuration of FlowMeter on Switch
Suite Teardown    Stop Tsdr Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{FLOWMETER_METRICS}    ByteInCount    PacketInCount    FlowCount
${TSDR_FLOWMETERSTATS}    tsdr:list FlowMeterStats
@{FLOWMETER_HEADER}    MetricName    MetricValue    MetricCategory    MetricDetails

*** Test Cases ***
Verify the FlowMeter Stats attributes exist thru Karaf console
    [Documentation]    Verify the FlowMeterStats attributes exist on Karaf Console
    Wait Until Keyword Succeeds    120s    1s    Verify the Metric is Collected?    ${TSDR_FLOWMETERSTATS}    ByteInCount
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    ${output}=    Issue Command On Karaf Console    ${TSDR_FLOWMETERSTATS}
    Close Karaf Console
    : FOR    ${list}    IN    @{FLOWMETER_METRICS}
    \    Should Contain    ${output}    ${list}

Verification of FlowMeterStats-ByteInCount on Karaf Console
    [Documentation]    Verify the FlowMeterStats has been updated thru tsdr:list command on karaf console
    ${tsdr_cmd}=    Concatenate the String    ${TSDR_FLOWMETERSTATS}    | grep ByteInCount | head
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    90
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}
    Close Karaf Console
    Should Contain    ${output}    ByteInCount
    Should Contain    ${output}    FLOWMETERSTATS
    Should not Contain    ${output}    null
    : FOR    ${list}    IN    @{FLOWMETER_HEADER}
    \    Should Contain    ${output}    ${list}

Verify FlowMeterStats-Attributes on H2 Datastore using JDBC Client
    [Documentation]    Verify the FlowMeterStats,attributes on H2 Datastore using JDBC Client
    : FOR    ${list}    IN    @{FLOWMETER_METRICS}
    \    ${output}=    Query Metrics on H2 Datastore    FLOWMETERSTATS    ${list}
    \    Should Contain    ${output}    ${list}

Uninstall all TSDR H2 Feature
    [Documentation]    UnInstall all TSDR H2 Features
    Uninstall a Feature    odl-tsdr-H2-persistence odl-tsdr-all odl-tsdr-core
    Verify Feature Is Not Installed    odl-tsdr-H2-persistence
    Verify Feature Is Not Installed    odl-tsdr-all
    Verify Feature Is Not Installed    odl-tsdr-core

Verification TSDR Command shouldnot exist in help
    [Documentation]    Verify the TSDR List command on help
    ${output}=    Issue Command On Karaf Console    tsdr\t
    Should not Contain    ${output}    tsdr:list

*** Keyword ***
Start TSDR suite with CPqD Switch
    Start Tsdr Suite    user

Configuration of FlowMeter on Switch
    [Documentation]    FlowMeter configuration on CPqD
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s1 meter-mod cmd=add,flags=1,meter=1 drop:rate=100
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s1 flow-mod table=0,cmd=add in_port=1 meter:1 apply:output=2
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s1 ping 10
    Run Command On Remote System    ${MININET}    sudo dpctl unix:/tmp/s2 ping 10

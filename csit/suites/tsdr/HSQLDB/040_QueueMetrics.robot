*** Settings ***
Documentation     Test suite for HSQLDB DataStore Queue Metrics Verification
Suite Setup       Run Keywords    Start Tsdr Suite    Configuration of Queue on Switch
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

*** Test Cases ***
Init Variables
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_VERSION}
    Run Keyword If    '${ODL_VERSION}' == 'stable-lithium'    Init Variables Lithium
    ...    ELSE    Init Variables Master

Verify the QueueStats attributes exist thru Karaf console
    [Documentation]    Verify the QueueMetrics attributes exist on Karaf Console
    Wait Until Keyword Succeeds    60s    1s    Verify the Metric is Collected?    ${TSDR_QUEUE_STATS}    Transmitted
    ${output}=    Issue Command On Karaf Console    ${TSDR_QUEUE_STATS}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{QUEUE_METRICS}
    \    Should Contain    ${output}    ${list}

*** Keyword ***
Configuration of Queue on Switch
    [Documentation]    Queue configuration on openvswitch
    Configure the Queue on Switch    s2-eth2

Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Suite Variable    ${TSDR_QUEUE_STATS}    tsdr:list QUEUESTATS

Init Variables Lithium
    [Documentation]    Sets variables specific to Lithium version
    Set Suite Variable    ${TSDR_QUEUE_STATS}    tsdr:list QueueStats

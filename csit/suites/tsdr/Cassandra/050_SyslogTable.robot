*** Settings ***
Documentation     Test suite for Cassandra DataStore Syslog Verification
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Verification of TSDR Cassandra Feature Installation
    [Documentation]    Install and Verify the TSDR Cassandra Syslog Features
    Initialize Cassandra Tables Metricval    val_table=metriclog
    Wait Until Keyword Succeeds    24x    10 sec    Check Karaf Log Has Messages    tsdr.syslog
    Verify Feature Is Installed    odl-tsdr-cassandra
    Verify Feature Is Installed    odl-tsdr-syslog-collector

Sending syslog to ODL Syslog collector using Logger command
    [Documentation]    Sending Syslogs to collector.
    : FOR    ${key}    IN ZIP    &{syslog_facility}
    \    ${value}=    Get From Dictionary    ${syslog_facility}    ${key}
    \    ${f_value}=    Evaluate    ${value} * 8
    \    Generate Syslog    ${f_value}

Verifying TSDR Data Store For Syslog Entries
    [Documentation]    Verifying if syslogs is getting stored.
    Copy TSDR tables    val_table=metriclog
    ${metric_log}=    Verify the Metrics Syslog on Cassandra Client    grep DC=SYSLOG
    @{Syslogs}=    Split to lines    ${metric_log}
    ${iterator}=    Set Variable    0
    : FOR    ${key}    IN ZIP    &{syslog_facility}
    \    ${value}=    Get From Dictionary    ${syslog_facility}    ${key}
    \    ${f_value}=    Evaluate    ${value} * 8
    \    Should Contain    @{syslogs}[${iterator}]    ${MESSAGE}
    \    Should Contain    @{syslogs}[${iterator}]    <${f_value}>
    \    ${iterator}=    Evaluate    ${iterator} + 1

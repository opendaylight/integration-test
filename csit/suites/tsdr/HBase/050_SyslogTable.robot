*** Settings ***
Documentation     Test suite for HBase Syslog Verification
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Verification of TSDR HBase Feature Installation
    [Documentation]    Install and Verify the TSDR Cassandra Syslog Features
    Wait Until Keyword Succeeds    24x    10 sec    Check Karaf Log Has Messages    tsdr.syslog
    Verify Feature Is Installed    odl-tsdr-hbase
    Verify Feature Is Installed    odl-tsdr-syslog-collector

Sending syslog to ODL Syslog collector using Logger command
    [Documentation]    Verifying if syslogs is collected and getting stored.
    Query the Data from HBaseClient    truncate 'SYSLOG'
    : FOR    ${key}    IN ZIP    &{syslog_facility}
    \    ${value}=    Get From Dictionary    ${syslog_facility}    ${key}
    \    ${f_value}=    Evaluate    ${value} * 8
    \    Generate Syslog    ${f_value}
    ${output}=    Query the Data from HBaseClient    scan 'SYSLOG'
    Should Contain X Times    ${output}    ${MESSAGE_PATTERN}    1
    : FOR    ${key}    IN ZIP    &{syslog_facility}
    \    ${value}=    Get From Dictionary    ${syslog_facility}    ${key}
    \    ${f_value}=    Evaluate    ${value} * 8
    \    Should Match    ${output}    *${f_value}>*

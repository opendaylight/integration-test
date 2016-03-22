*** Settings ***
Documentation     Test suite for HSQLDB DataStore Syslog Stats Verification
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Verification of TSDR HSQLDB Feature Installation
    [Documentation]    Install and Verify the TSDR Cassandra Syslog Features
    COMMENT    Install a Feature    odl-tsdr-hsqldb-all    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    COMMENT    Install a Feature    odl-tsdr-syslog-collector    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    60
    Wait Until Keyword Succeeds    24x    10 sec    Check Karaf Log Has Messages    tsdr.syslog
    Verify Feature Is Installed    odl-tsdr-hsqldb
    Verify Feature Is Installed    odl-tsdr-syslog-collector

Sending syslog to ODL Syslog collector using Logger command
    [Documentation]    Verifying if syslogs is getting generated.
    : FOR    ${key}    IN ZIP    &{syslog_facility}
    \    ${value}=    Get From Dictionary    ${syslog_facility}    ${key}
    \    ${f_value}=    Evaluate    ${value} * 8
    \    Generate Syslog    ${f_value}
    Wait Until Keyword Succeeds    24x    10 sec    Check HSQLDB    1    SYSLOG | grep SYSLOG | wc -l

Verifying TSDR Data Store For Syslog Entries
    [Documentation]    Verifying if syslogs is getting stored.
    ${output}=    Issue Command On Karaf Console    tsdr:list SYSLOG
    Should Contain X Times    ${output}    SYSLOG    1
    Should Contain    ${output}    ${MESSAGE_PATTERN}

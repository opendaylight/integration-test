*** Settings ***
Documentation     Test suite for HSQLDB DataStore Syslog Stats Verification
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/TsdrUtils.robot
Variables         ../../../variables/Variables.py


*** Variables ***
&{syslog_facility}    kern=0    user=1    mail=2    daemon=3    auth=4    syslog=5    lpr=6    news=7    uucp=8
...                    authpriv=10    ftp=11    local0=16    local1=17    local2=18    local3=19
...                    local4=20    local5=21    local6=22    local7=23
&{syslog_severity}    emerg=0    alert=1    crit=2    err=3    warning=4    notice=5    info=6    debug=7
${MESSAGE}    Oct 29 18:10:31: ODL: %STKUNIT0-M:CP %IFMGR-5-ASTATE_UP: Changed interface Admin state to up: Te 0/0
${MESSAGE_PATTERN}    Changed interface

*** Test Cases ***

Verification of TSDR HSQLDB Feature Installation
    [Documentation]    Install and Verify the TSDR Cassandra Syslog Features
    COMMENT    Install a Feature    odl-tsdr-hsqldb-all    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    COMMENT    Install a Feature    odl-tsdr-syslog-collector    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    Wait Until Keyword Succeeds    24x    10 sec    Check Karaf Log Has Messages    tsdr.syslog
    Verify Feature Is Installed    odl-tsdr-hsqldb
    Verify Feature Is Installed    odl-tsdr-syslog-collector


Sending syslog to ODL Syslog collector using Logger command

    :FOR    ${key}    IN ZIP   &{syslog_facility}
    \    ${value}=    Get From Dictionary    ${syslog_facility}    ${key}
    \    Severity Iterator    ${key}    ${MESSAGE}    ${syslog_severity}
    Wait Until Keyword Succeeds    24x    10 sec    Check HSQLDB    152    SYSLOG | grep SYSLOG | wc -l

Verifying TSDR Data Store For Syslog Entries

    ${output}=    Issue Command On Karaf Console    tsdr:list SYSLOG
    Should Contain X Times    ${output}    SYSLOG   152
    Should Contain    ${output}    ${MESSAGE_PATTERN}


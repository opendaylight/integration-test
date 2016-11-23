*** Settings ***
Documentation     Test suite for backing up data and models
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           DateTime
Resource          ../../libraries/DaeximKeywords.robot

*** Test Cases ***
Create and Cancel Backup
    [Documentation]    schedule and cancel backup of a cluster
    [Tags]    cancel backup
    DaeximKeywords.Verify Backup Status    initial    1
    DaeximKeywords.Schedule Backup    1
    DaeximKeywords.Verify Backup Status    scheduled    1
    DaeximKeywords.Cancel Backup    1
    DaeximKeywords.Verify Backup Status    initial    1

Schedule Absolute Time Backup With UTC
    [Documentation]    Schedule backup at a particular time
    [Tags]    absolute time backup
    ${time}    DateTime.Get Current Date    UTC    00:00:10    %Y-%m-%dT%H:%M:%SZ    ${FALSE}
    DaeximKeywords.Schedule Backup    1    ${ODL_SYSTEM_IP}    ${time}
    BuiltIn.Wait Until Keyword Succeeds    20 sec    5 sec    DaeximKeywords.Verify Scheduled Backup Timestamp    1    ${time}
    Builtin.Wait Until Keyword Succeeds    20 sec    5 sec    DaeximKeywords.Verify Backup Status    complete    1
    DaeximKeywords.Verify Backup Files

Schedule Absolute Time Backup With Localtime
    [Documentation]    Schedule backup at a particular time
    [Tags]    absolute time backup
    ${time}    DateTime.Get Current Date    local    00:00:10    %Y-%m-%dT%H:%M:%S+000    ${FALSE}
    Builtin.Run Keyword And Expect Error    *    Schedule Backup    1    ${ODL_SYSTEM_IP}    ${time}

Schedule Absolute Time Backup In Past
    [Documentation]    Schedule backup at a particular time
    [Tags]    absolute time backup
    ${time}    DateTime.Get Current Date    UTC    -00:00:10    %Y-%m-%dT%H:%M:%SZ    ${FALSE}
    Builtin.Run Keyword And Expect Error    *    Schedule Backup    1    ${ODL_SYSTEM_IP}    ${time}

Create Module Exclude Backup
    [Documentation]    schedule backup with exclude option on a cluster
    [Tags]    exclude backup
    ${file1}    DaeximKeywords.Schedule Exclude Backup    1    config    network-topology
    ${lines1}    OperatingSystem.Grep File    ${file1}    network-topology:
    Builtin.Should Be Empty    ${lines1}
    ${file2}    DaeximKeywords.Schedule Exclude Backup    1    operational    opendaylight-inventory
    ${lines2}    OperatingSystem.Grep File    ${file2}    opendaylight-inventory:
    Builtin.Should Be Empty    ${lines2}

Create Wildcard Exclude Backup
    [Documentation]    schedule backup with wildstar exclude option
    [Tags]    wildcard exclude backup
    ${file1}    DaeximKeywords.Schedule Exclude Backup    1    config    *
    ${lines1}    Operating System.Get File    ${file1}
    Builtin.Should Be Equal    ${lines1}    {}
    ${file2}    Schedule Exclude Backup    1    operational    *
    ${lines2}    Operating System.Get File    ${file2}
    Builtin.Should Be Equal    ${lines2}    {}

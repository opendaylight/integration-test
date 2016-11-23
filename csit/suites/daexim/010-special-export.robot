*** Settings ***
Documentation     Test suite for backing up data and models
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Library           String
Library           DateTime
Resource          ../../variables/Variables.robot
Resource          ../../variables/daexim/DaeximVariables.robot
Resource          ../../libraries/DaeximKeywords.robot
Resource          ../../libraries/ClusterOpenFlow.robot
Variables         ../../variables/Variables.py

*** Test Cases ***
Create and Cancel Backup
    [Documentation]     schedule and cancel backup of a cluster
    [Tags]    cancel backup
    Verify Backup Status    initial    1
    Schedule Backup    1
    Verify Backup Status    scheduled    1
    Cancel Backup    1
    Verify Backup Status    initial    1

Schedule Absolute Time Backup With UTC
    [Documentation]    Schedule backup at a particular time
    [Tags]    absolute time backup
    ${time}    Get Current Date    UTC    00:00:10    %Y-%m-%dT%H:%M:%SZ    ${FALSE}
    Schedule Backup    1    ${CONTROLLER}    ${time}
    Wait Until Keyword Succeeds    20 sec    5 sec    Verify Scheduled Backup Timestamp    1    ${time}
    Wait Until Keyword Succeeds    20 sec    5 sec    Verify Backup Status    complete    1
    Verify Backup Files

Schedule Absolute Time Backup With Localtime
    [Documentation]    Schedule backup at a particular time
    [Tags]    absolute time backup
    ${time}    Get Current Date    local    00:00:10    %Y-%m-%dT%H:%M:%S+000    ${FALSE}
    Run Keyword And Expect Error    *    Schedule Backup    1    ${CONTROLLER}    ${time}

Schedule Absolute Time Backup In Past
    [Documentation]    Schedule backup at a particular time
    [Tags]    absolute time backup
    ${time}    Get Current Date    UTC    -00:00:10    %Y-%m-%dT%H:%M:%SZ    ${FALSE}
    Run Keyword And Expect Error    *    Schedule Backup    1    ${CONTROLLER}    ${time}

Create Module Exclude Backup
    [Documentation]     schedule backup with exclude option on a cluster
    [Tags]    exclude backup
    ${file1}    Schedule Exclude Backup    1    config    network-topology
    ${lines1}    Grep File   ${file1}     network-topology:
    Should Be Empty    ${lines1}
    ${file2}    Schedule Exclude Backup    1    operational    opendaylight-inventory
    ${lines2}    Grep File    ${file2}    opendaylight-inventory:
    Should Be Empty    ${lines2}

Create Wildcard Exclude Backup
    [Documentation]     schedule backup with wildstar exclude option
    [Tags]    wildcard exclude backup
    ${file1}    Schedule Exclude Backup    1    config    *
    ${lines1}    Operating System.Get File   ${file1}
    Should Be Equal    ${lines1}    {}
    ${file2}    Schedule Exclude Backup    1    operational    *
    ${lines2}    Operating System.Get File   ${file2}
    Should Be Equal    ${lines2}    {}

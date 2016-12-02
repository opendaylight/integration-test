*** Settings ***
Documentation     Test suite for verifying basic variations of export API including checking statuses
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           DateTime
Resource          ../../libraries/DaeximKeywords.robot

*** Test Cases ***
Create and Cancel Export
    [Documentation]    schedule and cancel export of a cluster
    [Tags]    cancel export
    DaeximKeywords.Verify Export Status    ${EXPORT_INITIAL_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Schedule Export    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Status    ${EXPORT_SCHEDULED_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Cancel Export    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Status    ${EXPORT_INITIAL_STATUS}    ${FIRST_CONTROLLER_INDEX}

Schedule Absolute Time Export With UTC
    [Documentation]    Schedule export at a particular time
    [Tags]    absolute time export
    ${time}    DateTime.Get Current Date    UTC    00:00:10    %Y-%m-%dT%H:%M:%SZ    ${FALSE}
    DaeximKeywords.Schedule Export    ${FIRST_CONTROLLER_INDEX}    ${time}
    BuiltIn.Wait Until Keyword Succeeds    20 sec    5 sec    DaeximKeywords.Verify Scheduled Export Timestamp    ${FIRST_CONTROLLER_INDEX}    ${time}
    Builtin.Wait Until Keyword Succeeds    20 sec    5 sec    DaeximKeywords.Verify Export Status    ${EXPORT_COMPLETE_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Files    ${FIRST_CONTROLLER_INDEX}

Schedule Absolute Time Export With Localtime
    [Documentation]    Schedule export at a particular time
    [Tags]    absolute time export
    ${time}    DateTime.Get Current Date    local    00:00:10    %Y-%m-%dT%H:%M:%S+000    ${FALSE}
    Builtin.Run Keyword And Expect Error    *    Schedule Export    ${FIRST_CONTROLLER_INDEX}    ${time}

Schedule Absolute Time Export In Past
    [Documentation]    Schedule export at a particular time
    [Tags]    absolute time export
    ${time}    DateTime.Get Current Date    UTC    -00:00:10    %Y-%m-%dT%H:%M:%SZ    ${FALSE}
    Builtin.Run Keyword And Expect Error    *    Schedule Export    ${FIRST_CONTROLLER_INDEX}    ${time}

Create Module Exclude Export
    [Documentation]    schedule export with exclude option on a cluster
    [Tags]    exclude export
    ${file1}    DaeximKeywords.Schedule Exclude Export    ${FIRST_CONTROLLER_INDEX}    config    network-topology
    ${lines1}    OperatingSystem.Grep File    ${file1}    network-topology:
    Builtin.Should Be Empty    ${lines1}
    ${file2}    DaeximKeywords.Schedule Exclude Export    ${FIRST_CONTROLLER_INDEX}    operational    opendaylight-inventory
    ${lines2}    OperatingSystem.Grep File    ${file2}    opendaylight-inventory:
    Builtin.Should Be Empty    ${lines2}

Create Wildcard Exclude Export
    [Documentation]    schedule export with wildstar exclude option
    [Tags]    wildcard exclude export
    ${file1}    DaeximKeywords.Schedule Exclude Export    ${FIRST_CONTROLLER_INDEX}    config    *
    ${lines1}    Operating System.Get File    ${file1}
    Builtin.Should Be Equal    ${lines1}    {}
    ${file2}    Schedule Exclude Export    ${FIRST_CONTROLLER_INDEX}    operational    *
    ${lines2}    Operating System.Get File    ${file2}
    Builtin.Should Be Equal    ${lines2}    {}

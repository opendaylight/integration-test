*** Settings ***
Documentation     Test suite for verifying basic export with inclusions
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../libraries/DaeximKeywords.robot

*** Test Cases ***
Create Module Include Export
    [Documentation]    schedule a basic export/backup with applied inclusion pattern
    [Tags]    include export
    ${file1}    DaeximKeywords.Schedule Include Export    ${FIRST_CONTROLLER_INDEX}    config    network-topology
    ${lines1}    OperatingSystem.Grep File    ${file1}    network-topology:
    Builtin.Should Not Be Empty    ${lines1}

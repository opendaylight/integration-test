*** Settings ***
Documentation     Test suite for verifying basic export with inclusions
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../libraries/DaeximKeywords.robot

*** Test Cases ***
Create Module Include Export
    [Documentation]    schedule a basic export/backup with applied inclusion pattern
    [Tags]    inclusions    export
    # Module is just included
    ${file1}    DaeximKeywords.Schedule Include Export    ${FIRST_CONTROLLER_INDEX}    config    network-topology    ${FALSE}
    ${lines1}    OperatingSystem.Grep File    ${file1}    network-topology:
    Builtin.Should Not Be Empty    ${lines1}
    # Module is both included and excluded
    ${file1}    DaeximKeywords.Schedule Include Export    ${FIRST_CONTROLLER_INDEX}    config    network-topology    ${TRUE}
    ${lines1}    OperatingSystem.Grep File    ${file1}    network-topology:
    Builtin.Should Be Empty    ${lines1}

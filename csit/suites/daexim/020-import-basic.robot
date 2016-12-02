*** Settings ***
Documentation     Test suite for verifying basic import
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../libraries/DaeximKeywords.robot

*** Test Cases ***
Create Basic Import
    [Documentation]    schedule a basic import/restore with data containg controller mounting itself as a netconf device
    [Tags]    create restore
    DaeximKeywords.Cleanup The Export Files    ${FIRST_CONTROLLER_INDEX}
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    DaeximKeywords.Copy Config Data To Controller    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Schedule Import    ${FIRST_CONTROLLER_INDEX}
    Builtin.Wait Until Keyword Succeeds    30 sec    5 sec    DaeximKeywords.Verify Netconf Mount    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}

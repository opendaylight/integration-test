*** Settings ***
Documentation       Test suite for verifying basic import

Resource            ../../libraries/DaeximKeywords.robot

Suite Setup         ClusterManagement Setup
Suite Teardown      Delete All Sessions


*** Test Cases ***
Create Basic Import
    [Documentation]    schedule a basic import/restore with data containg controller mounting itself as a NETCONF
    ...    device. The configuration is documented in
    ...    https://docs.opendaylight.org/projects/netconf/en/latest/user-guide.html#spawning-new-netconf-connectors
    [Tags]    create restore
    DaeximKeywords.Cleanup The Export Files    ${FIRST_CONTROLLER_INDEX}
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    DaeximKeywords.Copy Config Data To Controller    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Schedule Import    ${FIRST_CONTROLLER_INDEX}
    Builtin.Sleep    5 sec    Wait for completion of import processing
    Builtin.Wait Until Keyword Succeeds
    ...    30 sec
    ...    5 sec
    ...    DaeximKeywords.Verify Netconf Mount
    ...    ${NETCONF_EP_NAME}
    ...    ${FIRST_CONTROLLER_INDEX}

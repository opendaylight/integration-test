*** Settings ***
Documentation     Test suite for verifying basic export with a netconf mount on a cluster
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../libraries/DaeximKeywords.robot

*** Test Cases ***
Create Basic Export
    [Documentation]    schedule a basic export/backup on a cluster, with controller mounting itself as a netconf device
    [Tags]    create backup
    DaeximKeywords.Mount Netconf Endpoint    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Cleanup The Export Files    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Cleanup The Export Files    ${SECOND_CONTROLLER_INDEX}
    DaeximKeywords.Cleanup The Export Files    ${THIRD_CONTROLLER_INDEX}
    DaeximKeywords.Schedule Export    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Status    ${EXPORT_SCHEDULED_STATUS}    ${SECOND_CONTROLLER_INDEX}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    DaeximKeywords.Verify Export Status    ${EXPORT_COMPLETE_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Files    ${SECOND_CONTROLLER_INDEX}
    DaeximKeywords.Verify Netconf Mount    ${NETCONF_EP_NAME}    ${THIRD_CONTROLLER_INDEX}

*** Settings ***
Documentation     Test suite for verifying basic export only on a local node with a netconf mount on a cluster
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../libraries/DaeximKeywords.robot

*** Test Cases ***
Create Basic Local Export
    [Documentation]    schedule a basic export/backup on a cluster node, with controller mounting itself as a netconf device.Verifies if the export is limited to a local node.
    [Tags]    create backup
    DaeximKeywords.Mount Netconf Endpoint    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Cleanup Cluster Export Files
    DaeximKeywords.Schedule Export    ${FIRST_CONTROLLER_INDEX}    500    ${FALSE}    ${EMPTY}    ${EMPTY}    true
    DaeximKeywords.Verify Export Status    ${EXPORT_SCHEDULED_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Status    ${EXPORT_SKIPPED_STATUS}    ${SECOND_CONTROLLER_INDEX}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    DaeximKeywords.Verify Export Status    ${EXPORT_COMPLETE_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Files    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Files Not Present    ${THIRD_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Files Not Present    ${SECOND_CONTROLLER_INDEX}
    DaeximKeywords.Verify Netconf Mount    ${NETCONF_EP_NAME}    ${THIRD_CONTROLLER_INDEX}

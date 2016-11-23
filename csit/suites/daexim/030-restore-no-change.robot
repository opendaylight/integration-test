*** Settings ***
Documentation     Test suite for restoring the backed-up data and models
Suite Setup       Setup Environment for Restore Testcases
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Library           String
Resource          ../../variables/daexim/DaeximVariables.robot

*** Test Cases ***
Restore Backup
    [Documentation]     restore and verify
    [Tags]    restore
    ${restore_host}    Get Variable Value    ${CONTROLLER01}    ${CONTROLLER1}
    Log    ${restore_host}
    ${restore_location}    Change File String    ${BKP_DIR}    ${TARGET_LINE}    ${TARGET_LINE}    ${BKP_DATA_FILE}    ${restore_host}
    Run Keyword If Not Package Manager Installation    Copy Test VM Backup Directory To The Controller Zip    ${CONTROLLER}
    Run Keyword If Package Manager Installation    Copy Test VM Backup Directory To The Controller Packaging    ${CONTROLLER}
    ${host_ip}    Pick A Random Host IP
    Restore Backup    ${host_ip}
    Verify Import Status    complete
    Verify Netconf Mount    ${ENDPOINT_1}
    Collect Support Diags

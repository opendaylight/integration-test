*** Settings ***
Library           OperatingSystem
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           backuprestore/JsonDiffTool.py
Resource          ClusterManagement.robot
Resource          ../variables/daexim/DaeximVariables.robot
Resource          DaeximKeywords.robot
Resource          ../variables/backuprestore/BackupRestoreVariables.robot
Resource          ../variables/Variables.robot
Resource          Utils.robot

*** Keywords ***
Set Global Variable If It Does Not Exist
    [Arguments]    ${name}    ${value}
    [Documentation]    Checks whether a given variable has been defined. If it does not, sets the passed value to that global variable
    ${status}    ${message} =    Run Keyword And Ignore Error    Variable Should Exist    ${name}
    Run Keyword If    "${status}" == "FAIL"    Set Global Variable    ${name}    ${value}

Perform Export
    [Arguments]    ${controller_index}
    [Documentation]    schedule a basic export/backup, waiting for completion
    [Tags]    create backup
    DaeximKeywords.Schedule Export    ${controller_index}
    DaeximKeywords.Verify Export Status    ${EXPORT_SCHEDULED_STATUS}    ${controller_index}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    DaeximKeywords.Verify Export Status    ${EXPORT_COMPLETE_STATUS}    ${controller_index}
    DaeximKeywords.Verify Export Files    ${controller_index}

ConditionalBackupRestoreCheck
    [Arguments]    ${exclusionsConfigBefore}=${EMPTY}    ${exclusionsConfigAfter}=${EMPTY}    ${exclusionsOperationalBefore}=${EMPTY}    ${exclusionsOperationalAfter}=${EMPTY}    ${odlControllerIndex}=${FIRST_CONTROLLER_INDEX}
    [Documentation]    When enabled, performs a datastore export, then a backup, then a restore, then an export. The check is considered to be failed when exports before and after are different (two different json path files can be passed in order to filter certain subtrees from the export files before / after the export)
    Set Global Variable If It Does Not Exist    \${BR_TESTING_ENABLED}    FALSE
    Return From Keyword If    '${BR_TESTING_ENABLED}'!='true'
    BackupRestoreCheck    ${exclusionsConfigBefore}    ${exclusionsConfigAfter}    ${exclusionsOperationalBefore}    ${exclusionsOperationalAfter}    ${odlControllerIndex}

BackupRestoreCheck
    [Arguments]    ${exclusionsConfigBefore}=${EMPTY}    ${exclusionsConfigAfter}=${EMPTY}    ${exclusionsOperationalBefore}=${EMPTY}    ${exclusionsOperationalAfter}=${EMPTY}    ${odlControllerIndex}=${FIRST_CONTROLLER_INDEX}
    [Documentation]    When enabled, performs a datastore export, then a backup, then a restore, then an export. The check is considered to be failed when exports before and after are different (two different json path files can be passed in order to filter certain subtrees from the export files before / after the export)
    Log    Performing backup-restore check
    ${ARG_CONFIG_BEFORE}=    Set Variable    ' '
    ${ARG_CONFIG_AFTER}=    Set Variable    ' '
    ${ARG_OPER_BEFORE}=    Set Variable    ' '
    ${ARG_OPER_AFTER}=    Set Variable    ' '
    ${ARG_CONFIG_BEFORE}=    Run Keyword If    '${exclusionsConfigBefore}'!='${EMPTY}'    '${exclusionsConfigBefore}'
    ${ARG_CONFIG_AFTER}=    Run Keyword If    '${exclusionsConfigAfter}'!='${EMPTY}'    '${exclusionsConfigAfter}'
    ${ARG_OPER_BEFORE}=    Run Keyword If    '${exclusionsOperationalBefore}'!='${EMPTY}'    Normalize Path    ${CURDIR}/${exclusionsOperationalBefore}
    ${ARG_OPER_AFTER}=    Run Keyword If    '${exclusionsOperationalAfter}'!='${EMPTY}'    Normalize Path    ${CURDIR}/${exclusionsOperationalAfter}
    ${controller_index}    Builtin.Convert To Integer    ${odlControllerIndex}
    Perform Export    ${controller_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${controller_index}
    ${directory_exist}    Builtin.Run Keyword And Return Status    OperatingSystem.Directory Should Exist    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}
    Builtin.Run Keyword If    ${directory_exist}    Cleanup Directory    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}
    Copy Export Directory To Test VM    ${host}
    OperatingSystem.Move Directory    ${EXP_DIR}${host}    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}
    #
    # TODO: Insert The Backup + Restore call here
    #
    Log    doing the second export!
    Perform Export    ${controller_index}
    Copy Export Directory To Test VM    ${host}
    ${directory_exist}    Builtin.Run Keyword And Return Status    OperatingSystem.Directory Should Exist    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}
    Builtin.Run Keyword If    ${directory_exist}    Cleanup Directory    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}
    OperatingSystem.Move Directory    ${EXP_DIR}${host}    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}
    log    "Performing comparison"
    ${differencesConfigDatastore}=    Json Diff Check Keyword    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}/${EXP_DATA_FILE}    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}/${EXP_DATA_FILE}    ${ARG_CONFIG_BEFORE}    ${ARG_CONFIG_AFTER}
    ${differencesOperationalDatastore}=    Json Diff Check Keyword    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}/${EXP_OPER_FILE}    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}/${EXP_OPER_FILE}    ${ARG_OPER_BEFORE}    ${ARG_OPER_AFTER}
    Should Be Equal    '0'    '${differencesConfigDatastore}'    Error: Diferences found in the config DS before backup / after restore
    Should Be Equal    '0'    '${differencesOperationalDatastore}'    Error: Diferences found in the config DS before backup / after restore

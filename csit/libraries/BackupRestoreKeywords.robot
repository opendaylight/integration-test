*** Settings ***
Library     OperatingSystem
Library     SSHLibrary
Library     Collections
Library     RequestsLibrary
Library     backuprestore/JsonDiffTool.py
Resource    ClusterManagement.robot
Resource    ../variables/daexim/DaeximVariables.robot
Resource    DaeximKeywords.robot
Resource    ../variables/backuprestore/BackupRestoreVariables.robot
Resource    ../variables/Variables.robot
Resource    Utils.robot


*** Keywords ***
Set Global Variable If It Does Not Exist
    [Documentation]    Checks whether a given variable has been defined. If it does not, sets the passed value to that global variable
    [Arguments]    ${name}    ${value}
    ${status}    ${message}=    Run Keyword And Ignore Error    Variable Should Exist    ${name}
    IF    "${status}" == "FAIL"    Set Global Variable    ${name}    ${value}

Perform Export
    [Documentation]    schedule a basic export/backup, waiting for completion
    [Tags]    create backup
    [Arguments]    ${controller_index}
    DaeximKeywords.Schedule Export    ${controller_index}
    DaeximKeywords.Verify Export Status    ${EXPORT_SCHEDULED_STATUS}    ${controller_index}
    Builtin.Wait Until Keyword Succeeds
    ...    10 sec
    ...    5 sec
    ...    DaeximKeywords.Verify Export Status
    ...    ${EXPORT_COMPLETE_STATUS}
    ...    ${controller_index}
    DaeximKeywords.Verify Export Files    ${controller_index}

ConditionalBackupRestoreCheck
    [Documentation]    When enabled, performs a datastore export, then a backup, then a restore, then an export. The check is considered to be failed when exports before and after are different (two different json path files can be passed in order to filter certain subtrees from the export files before / after the export)
    [Arguments]    ${exclusionsConfigBefore}=${EMPTY}    ${exclusionsConfigAfter}=${EMPTY}    ${exclusionsOperationalBefore}=${EMPTY}    ${exclusionsOperationalAfter}=${EMPTY}    ${odlControllerIndex}=${FIRST_CONTROLLER_INDEX}
    Set Global Variable If It Does Not Exist    \${BR_TESTING_ENABLED}    FALSE
    IF    '${BR_TESTING_ENABLED}'!='true'    RETURN
    BackupRestoreCheck
    ...    ${exclusionsConfigBefore}
    ...    ${exclusionsConfigAfter}
    ...    ${exclusionsOperationalBefore}
    ...    ${exclusionsOperationalAfter}
    ...    ${odlControllerIndex}

BackupRestoreCheck
    [Documentation]    When enabled, performs a datastore export, then a backup, then a restore, then an export. The check is considered to be failed when exports before and after are different (two different json path files can be passed in order to filter certain subtrees from the export files before / after the export)
    [Arguments]    ${exclusionsConfigBefore}=${EMPTY}    ${exclusionsConfigAfter}=${EMPTY}    ${exclusionsOperationalBefore}=${EMPTY}    ${exclusionsOperationalAfter}=${EMPTY}    ${odlControllerIndex}=${FIRST_CONTROLLER_INDEX}
    Log    Performing backup-restore check
    ${ARG_CONFIG_BEFORE}=    Set Variable    ' '
    ${ARG_CONFIG_AFTER}=    Set Variable    ' '
    ${ARG_OPER_BEFORE}=    Set Variable    ' '
    ${ARG_OPER_AFTER}=    Set Variable    ' '
    IF    '${exclusionsConfigBefore}'!='${EMPTY}'
        ${ARG_CONFIG_BEFORE}=    '${exclusionsConfigBefore}'
    ELSE
        ${ARG_CONFIG_BEFORE}=    Set Variable    ${None}
    END
    IF    '${exclusionsConfigAfter}'!='${EMPTY}'
        ${ARG_CONFIG_AFTER}=    '${exclusionsConfigAfter}'
    ELSE
        ${ARG_CONFIG_AFTER}=    Set Variable    ${None}
    END
    IF    '${exclusionsOperationalBefore}'!='${EMPTY}'
        ${ARG_OPER_BEFORE}=    Normalize Path    ${CURDIR}/${exclusionsOperationalBefore}
    ELSE
        ${ARG_OPER_BEFORE}=    Set Variable    ${None}
    END
    IF    '${exclusionsOperationalAfter}'!='${EMPTY}'
        ${ARG_OPER_AFTER}=    Normalize Path    ${CURDIR}/${exclusionsOperationalAfter}
    ELSE
        ${ARG_OPER_AFTER}=    Set Variable    ${None}
    END
    ${controller_index}=    Builtin.Convert To Integer    ${odlControllerIndex}
    Perform Export    ${controller_index}
    ${host}=    ClusterManagement.Resolve IP Address For Member    ${controller_index}
    ${directory_exist}=    Builtin.Run Keyword And Return Status
    ...    OperatingSystem.Directory Should Exist
    ...    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}
    IF    ${directory_exist}
        Cleanup Directory    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}
    END
    Copy Export Directory To Test VM    ${host}
    OperatingSystem.Move Directory    ${EXP_DIR}${host}    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}
    #
    # TODO: Insert The Backup + Restore call here
    #
    Log    doing the second export!
    Perform Export    ${controller_index}
    Copy Export Directory To Test VM    ${host}
    ${directory_exist}=    Builtin.Run Keyword And Return Status
    ...    OperatingSystem.Directory Should Exist
    ...    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}
    IF    ${directory_exist}
        Cleanup Directory    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}
    END
    OperatingSystem.Move Directory    ${EXP_DIR}${host}    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}
    log    "Performing comparison"
    ${differencesConfigDatastore}=    Json Diff Check Keyword
    ...    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}/${EXP_DATA_FILE}
    ...    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}/${EXP_DATA_FILE}
    ...    ${ARG_CONFIG_BEFORE}
    ...    ${ARG_CONFIG_AFTER}
    ${differencesOperationalDatastore}=    Json Diff Check Keyword
    ...    ${EXP_DIR}/${RELATIVE_BEFORE_BACKUP_DIR}/${EXP_OPER_FILE}
    ...    ${EXP_DIR}/${RELATIVE_AFTER_RESTORE_DIR}/${EXP_OPER_FILE}
    ...    ${ARG_OPER_BEFORE}
    ...    ${ARG_OPER_AFTER}
    Should Be Equal
    ...    '0'
    ...    '${differencesConfigDatastore}'
    ...    Error: Diferences found in the config DS before backup / after restore
    Should Be Equal
    ...    '0'
    ...    '${differencesOperationalDatastore}'
    ...    Error: Diferences found in the config DS before backup / after restore

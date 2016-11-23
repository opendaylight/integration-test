*** Settings ***
Library           OperatingSystem
Resource          ../variables/Variables.robot
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Verify Backup Files
    [Arguments]    ${ip}=${ODL_SYSTEM_IP}
    [Documentation]    Verify if the backedup files are present in the controller
    ${cfg}    ${rc}    Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${BKP_DATA_FILE}
    Run Keyword If    "${rc}" != "0"    Fail    Return code is not equal to zero on this command
    ...    ELSE    Log    ${cfg}
    ${mdl}    ${rc}    Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}
    Run Keyword If    "${rc}" != "0"    Fail    Return code is not equal to zero on this command
    ...    ELSE    Log    ${mdl}
    ${opr}    ${rc}    Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${BKP_OPER_FILE}
    Run Keyword If    "${rc}" != "0"    Fail    Return code is not equal to zero on this command
    ...    ELSE    Log    ${opr}

Cleanup The Backup Files
    [Arguments]    ${ip}=${ODL_SYSTEM_IP}
    [Documentation]    Verify if the backup directory exists and delete the files if needed
    ${output}    ${rc}    Run Command On Controller    ${ip}    sudo rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim
    Run Keyword If    "${rc}" != "0"    Fail    Return code is not equal to zero on this command
    ...    ELSE    Log    ${output}

Verify Backup Status
    [Arguments]    ${status}    ${controller_index}
    [Documentation]    Verify backup status is as expected
    ${response_json}    ClusterManagement.Post As Json To Member    ${STATUS_BACKUP_URL}    ${EMPTY}    ${controller_index}
    Log    ${response_json}
    ${response_json}    Convert To String    ${response_json}
    Verify Backup Status Message    ${status}    ${response_json}

Verify Scheduled Backup Timestamp
    [Arguments]    ${controller_index}    ${time}
    [Documentation]    Verify backup timestamp is as expected
    ${response_json}    ClusterManagement.Post As Json To Member    ${STATUS_BACKUP_URL}    ${EMPTY}    ${controller_index}
    Log    ${response_json}
    ${response_json}    Convert To String    ${response_json}
    Should Match Regexp    ${response_json}    .*"run-at": "${time}"

Verify Backup Status Message
    [Arguments]    ${status}    ${output}
    Should Match Regexp    ${output}    "status": "${status}"
    Run Keyword If    "${status}" == "initial" or "${status}" == "scheduled"    Verify Json Files Not Present    ${output}
    ...    ELSE    Verify Json Files Present    ${output}

Verify Json Files Present
    [Arguments]    ${output}    ${config_json}=${BKP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${BKP_OPER_FILE}
    Should Match Regexp    ${output}    .*${config_json}
    Should Match Regexp    ${output}    .*${models_json}
    Should Match Regexp    ${output}    .*${operational_json}
    Log    Found all Json Files

Verify Json Files Not Present
    [Arguments]    ${output}    ${config_json}=${BKP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${BKP_OPER_FILE}
    Should Not Match Regexp    ${output}    .*${config_json}
    Should Not Match Regexp    ${output}    .*${models_json}
    Should Not Match Regexp    ${output}    .*${operational_json}
    Log    Did not Find all Json Files

Schedule Backup
    [Arguments]    ${controller_index}    ${host}=${CONTROLLER}    ${TIME}=500    ${exclude}=${FALSE}    ${MODULE}=${EMPTY}    ${STORE}=${EMPTY}
    ${file}    Set Variable If    ${exclude}    ${BACKUP_EXCLUDE_FILE}    ${BACKUP_FILE}
    ${JSON1}    OperatingSystem.Get File    ${file}
    ${JSON2}    Replace Variables    ${JSON1}
    #${body}    To Json    ${JSON2}
    Cleanup The Backup Files
    ${response_json}    ClusterManagement.Post As Json To Member    ${SCHEDULE_BACKUP_URL}    ${JSON2}    ${controller_index}

Schedule Exclude Backup
    [Arguments]    ${controller_index}    ${store}    ${module}
    [Documentation]    Schedules a backup with exclude option. Returns the file that has the excluded backup.
    Schedule Backup    ${controller_index}    ${CONTROLLER}    500    ${TRUE}    ${module}    ${store}
    Wait Until Keyword Succeeds    10 sec    5 sec    Verify Backup Status    complete    ${controller_index}
    Verify Backup Files
    Copy Backup Directory To Test VM
    ${backup_file}    Set Variable If    '${store}' == 'operational'    ${BKP_OPER_FILE}    ${BKP_DATA_FILE}
    ${file_path}    Join Path    ${BKP_DIR}${CONTROLLER}    ${backup_file}
    [Return]    ${file_path}

Cancel Backup
    [Arguments]    ${controller_index}
    [Documentation]    Cancel the export job
    ClusterManagement.Post As Json To Member    ${CANCEL_BACKUP_URL}    ${EMPTY}    ${controller_index}

Return ConnnectionID
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}
    [Documentation]    Returns the connection of any host. Defaults to controller
    ${conn_id}    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    [Return]    ${conn_id}

Cleanup Directory
    [Arguments]    ${dir}
    [Documentation]    Cleansup the given directory if it exists
    Empty Directory    ${dir}
    Remove Directory    ${dir}

Copy Backup Directory To Test VM
    [Arguments]    ${host}=${CONTROLLER}
    ${new_dir}    Set Variable    ${BKP_DIR}${host}
    ${directory_exist}    Run Keyword And Return Status    OperatingSystem.Directory Should Exist    ${new_dir}
    Run Keyword If    ${directory_exist}    Cleanup Directory    ${new_dir}
    ${connections}    Return ConnnectionID
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Directory Should Exist    ${WORKSPACE}/${BUNDLEFOLDER}/daexim
    SSHLibrary.Get Directory    ${WORKSPACE}/${BUNDLEFOLDER}/daexim    ${new_dir}
    SSHLibrary.Close Connection
    ${output}    OperatingSystem.List Files In Directory    ${new_dir}
    Log    ${output}
    ${fl}    OperatingSystem.Get File    ${new_dir}/${BKP_DATA_FILE}
    Log    ${fl}

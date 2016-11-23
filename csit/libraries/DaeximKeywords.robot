*** Settings ***
Library           OperatingSystem
Library           SSHLibrary
Resource          ClusterManagement.robot
Resource          ../variables/Variables.robot
Resource          ../variables/daexim/DaeximVariables.robot
Variables         ../variables/Variables.py
Resource          ../variables/Variables.robot
Resource          Utils.robot

*** Keywords ***
Verify Backup Files
    [Arguments]    ${ip}=${ODL_SYSTEM_IP}
    [Documentation]    Verify if the backedup files are present in the controller
    ${cfg}    ${rc}    Utils.Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${BKP_DATA_FILE}
    Builtin.Run Keyword If    "${rc}" != "0"    Builtin.Fail    Return code is not equal to zero on this command
    ...    ELSE    Builtin.Log    ${cfg}
    ${mdl}    ${rc}    Utils.Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}
    Builtin.Run Keyword If    "${rc}" != "0"    Builtin.Fail    Return code is not equal to zero on this command
    ...    ELSE    Builtin.Log    ${mdl}
    ${opr}    ${rc}    Utils.Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${BKP_OPER_FILE}
    Builtin.Run Keyword If    "${rc}" != "0"    Builtin.Fail    Return code is not equal to zero on this command
    ...    ELSE    Builtin.Log    ${opr}

Cleanup The Backup Files
    [Arguments]    ${ip}=${ODL_SYSTEM_IP}
    [Documentation]    Verify if the backup directory exists and delete the files if needed
    ${output}    ${rc}    Utils.Run Command On Controller    ${ip}    sudo rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim
    Builtin.Run Keyword If    "${rc}" != "0"    Fail    Return code is not equal to zero on this command
    ...    ELSE    Builtin.Log    ${output}

Verify Backup Status
    [Arguments]    ${status}    ${controller_index}
    [Documentation]    Verify backup status is as expected
    ${response_json}    ClusterManagement.Post As Json To Member    ${STATUS_BACKUP_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Verify Backup Status Message    ${status}    ${response_json}

Verify Scheduled Backup Timestamp
    [Arguments]    ${controller_index}    ${time}
    [Documentation]    Verify backup timestamp is as expected
    ${response_json}    ClusterManagement.Post As Json To Member    ${STATUS_BACKUP_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Builtin.Should Match Regexp    ${response_json}    .*"run-at": "${time}"

Verify Backup Status Message
    [Arguments]    ${status}    ${output}
    [Documentation]    Verify backup restconf response message is as expected
    Builtin.Should Match Regexp    ${output}    "status": "${status}"
    Builtin.Run Keyword If    "${status}" == "initial" or "${status}" == "scheduled"    Verify Json Files Not Present    ${output}
    ...    ELSE    Verify Json Files Present    ${output}

Verify Json Files Present
    [Arguments]    ${output}    ${config_json}=${BKP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${BKP_OPER_FILE}
    [Documentation]    Verify if the json files are generated after a backup/export
    Builtin.Should Match Regexp    ${output}    .*${config_json}
    Builtin.Should Match Regexp    ${output}    .*${models_json}
    Builtin.Should Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Found all Json Files

Verify Json Files Not Present
    [Arguments]    ${output}    ${config_json}=${BKP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${BKP_OPER_FILE}
    [Documentation]    Verify if the json files are not present under the daexim folder
    Builtin.Should Not Match Regexp    ${output}    .*${config_json}
    Builtin.Should Not Match Regexp    ${output}    .*${models_json}
    Builtin.Should Not Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Did not Find all Json Files

Schedule Backup
    [Arguments]    ${controller_index}    ${host}=${ODL_SYSTEM_IP}    ${TIME}=500    ${exclude}=${FALSE}    ${MODULE}=${EMPTY}    ${STORE}=${EMPTY}
    ${file}    Builtin.Set Variable If    ${exclude}    ${BACKUP_EXCLUDE_FILE}    ${BACKUP_FILE}
    ${JSON1}    OperatingSystem.Get File    ${file}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Cleanup The Backup Files
    ${response_json}    ClusterManagement.Post As Json To Member    ${SCHEDULE_BACKUP_URL}    ${JSON2}    ${controller_index}

Schedule Exclude Backup
    [Arguments]    ${controller_index}    ${store}    ${module}
    [Documentation]    Schedules a backup with exclude option. Returns the file that has the excluded backup.
    Schedule Backup    ${controller_index}    ${ODL_SYSTEM_IP}    500    ${TRUE}    ${module}    ${store}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    Verify Backup Status    complete    ${controller_index}
    Verify Backup Files
    Copy Backup Directory To Test VM
    ${backup_file}    Builtin.Set Variable If    '${store}' == 'operational'    ${BKP_OPER_FILE}    ${BKP_DATA_FILE}
    ${file_path}    OperatingSystem.Join Path    ${BKP_DIR}${ODL_SYSTEM_IP}    ${backup_file}
    [Return]    ${file_path}

Cancel Backup
    [Arguments]    ${controller_index}
    [Documentation]    Cancel the export job
    ClusterManagement.Post As Json To Member    ${CANCEL_BACKUP_URL}    ${EMPTY}    ${controller_index}

Return ConnnectionID
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}
    [Documentation]    Returns the connection of any host. Defaults to controller
    ${conn_id}    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Utils.Flexible SSH Login    ${user}    ${password}
    [Return]    ${conn_id}

Cleanup Directory
    [Arguments]    ${dir}
    [Documentation]    Cleans up the given directory if it exists
    OperatingSystem.Empty Directory    ${dir}
    OperatingSystem.Remove Directory    ${dir}

Copy Backup Directory To Test VM
    [Arguments]    ${host}=${ODL_SYSTEM_IP}
    [Documentation]    This keyword copies the daexim folder genereated in the controller to robot vm. This is done to editing if needed on the json files
    ${new_dir}    Builtin.Set Variable    ${BKP_DIR}${host}
    ${directory_exist}    Builtin.Run Keyword And Return Status    OperatingSystem.Directory Should Exist    ${new_dir}
    Builtin.Run Keyword If    ${directory_exist}    Cleanup Directory    ${new_dir}
    ${connections}    Return ConnnectionID
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Directory Should Exist    ${WORKSPACE}/${BUNDLEFOLDER}/daexim
    SSHLibrary.Get Directory    ${WORKSPACE}/${BUNDLEFOLDER}/daexim    ${new_dir}
    SSHLibrary.Close Connection
    ${output}    OperatingSystem.List Files In Directory    ${new_dir}
    Builtin.Log    ${output}
    ${fl}    OperatingSystem.Get File    ${new_dir}/${BKP_DATA_FILE}
    Builtin.Log    ${fl}

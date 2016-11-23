*** Settings ***
Library           OperatingSystem
Resource         ../variables/Variables.robot
Resource          Utils.robot
Variables         ../variables/Variables.py


*** Keywords ***
Verify Backup Files
    [Documentation]    Verify if the backedup files are present in the controller
    [Arguments]    ${ip}=${ODL_SYSTEM_IP}      
    ${cfg}     Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${BKP_DATA_FILE}
    Log    ${cfg}
    ${mdl}     Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}
    Log    ${mdl}
    ${opr}     Run Command On Controller    ${ip}    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${BKP_OPER_FILE}
    Log    ${opr}

Delete The Backup Files
    [Documentation]    Delete any pre existing backup json files
    [Arguments]    ${connections}
    Execute SSH Command Expect Success    ${DAEXIM_LOCATION}    sudo rm -rf *.json    ${connections}
    Execute SSH Command Expect Success    ${BVC_HOME}/controller/    sudo rm -rf daexim/    ${connections}

Cleanup The Backup Files
    [Documentation]    Verify if the backup directory exists and delete the files if needed
    [Arguments]    ${ip}=${ODL_SYSTEM_IP}      
    ${output}     Run Command On Controller    ${ip}    sudo rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim

Verify Backup Status
    [Documentation]    Verify backup status is as expected
    [Arguments]    ${status}    ${controller_index}
    ${response_json}    ClusterManagement.Post As Json To Member    ${STATUS_BACKUP_URL}    ${EMPTY}    ${controller_index}
    Log    ${response_json}
    ${response_json}    Convert To String    ${response_json}
    Verify Backup Status Message    ${status}    ${response_json}

Verify Scheduled Backup Timestamp
    [Documentation]    Verify backup timestamp is as expected
    [Arguments]    ${controller_index}    ${time}
    ${response_json}    ClusterManagement.Post As Json To Member    ${STATUS_BACKUP_URL}    ${EMPTY}    ${controller_index}
    Log    ${response_json}
    ${response_json}    Convert To String    ${response_json}
    Should Match Regexp    ${response_json}    .*"run-at": "${time}"

Verify Successful Backup Timestamp
    [Documentation]    Verify backup timestamp after a succesfull backup
    [Arguments]    ${host}    ${time}
    ${response_json}    Do Controller Post Expect Success    ${STATUS_BACKUP_URL}    ${EMPTY}    ${host}
    Log    ${response_json}
    ${response_json}    Convert To String    ${response_json}
    Should Match Regexp    ${response_json}    .*"last-change":"${time}"

Verify Backup Status Message
    [Arguments]    ${status}     ${output}
    Should Match Regexp    ${output}    "status": "${status}"
    Run Keyword If     "${status}" == "initial" or "${status}" == "scheduled"    Verify Json Files Not Present    ${output}    ELSE     Verify Json Files Present    ${output}

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
    Log     Did not Find all Json Files

Verify Import Status
    [Documentation]    Verify import status is as expected
    [Arguments]    ${status}
    @{host_list}    Create Controller List
    : FOR    ${host}    IN    @{host_list}
    \    ${response_json}    Do Controller Post Expect Success    ${STATUS_IMPORT_URL}    ${EMPTY}    ${host}
    \    Log    ${response_json}
    \    ${response_json}    Convert To String    ${response_json}
    \    Should Match Regexp    ${response_json}    "status":"${status}"

Restore Backup
    [Documentation]    Restore backup with check models set to true
    [Arguments]    ${host}=${CONTROLLER}    ${result}=true    ${reason}=${EMPTY}    ${payload}=${RESTORE_FILE}    ${FLAG}=data
    ${check}    Do Controller Get    ${TOPOLOGY_URL}
    Log    ${check[0].content}
    Log    ${check[0].status_code}
    Wait Until Keyword Succeeds    90 seconds    1 seconds    Do Controller Get Expect Success    restconf/modules    ${None}    ${host}
    ${JSON2}    OperatingSystem.Get File    ${payload}
    ${JSON1}    Replace Variables    ${JSON2}
    ${body}    To Json    ${JSON1}
    Log    ${body}
    ${response_json1}    Wait Until Keyword Succeeds    120 seconds    10 seconds    Do Controller Post Expect Success    ${RESTORE_BACKUP_URL}    ${body}    ${host}
    ${response_json}    Get From List     ${response_json1}     0
    ${response_json}    Convert To String    ${response_json}
    Log    ${response_json}
    Should Match Regexp    ${response_json}    .*"result":${result}
    Run Keyword If    "${reason}" != "${EMPTY}"    Should Match Regexp    ${response_json}    .*"reason":"${reason}

Schedule Backup
    [Arguments]    ${controller_index}    ${host}=${CONTROLLER}    ${TIME}=500    ${exclude}=${FALSE}    ${MODULE}=${EMPTY}    ${STORE}=${EMPTY}
    ${file}    Set Variable If    ${exclude}    ${BACKUP_EXCLUDE_FILE}    ${BACKUP_FILE}
    ${JSON1}    OperatingSystem.Get File    ${file}
    ${JSON2}   Replace Variables    ${JSON1}
    #${body}    To Json    ${JSON2}
    Cleanup The Backup Files
    ${response_json}    ClusterManagement.Post As Json To Member    ${SCHEDULE_BACKUP_URL}    ${JSON2}    ${controller_index}

Schedule Exclude Backup
    [Documentation]    Schedules a backup with exclude option. Returns the file that has the excluded backup.
    [Arguments]    ${controller_index}    ${store}    ${module}
    Schedule Backup    ${controller_index}    ${CONTROLLER}    500   ${TRUE}    ${module}    ${store}
    Wait Until Keyword Succeeds    10 sec    5 sec    Verify Backup Status    complete    ${controller_index}
    Verify Backup Files
    Copy Backup Directory To Test VM
    ${backup_file}   Set Variable If    '${store}' == 'operational'    ${BKP_OPER_FILE}    ${BKP_DATA_FILE}
    ${file_path}    Join Path    ${BKP_DIR}${CONTROLLER}    ${backup_file}
    [Return]    ${file_path}

Cancel Backup
    [Documentation]    Cancel the export job
    [Arguments]    ${controller_index}
    ClusterManagement.Post As Json To Member    ${CANCEL_BACKUP_URL}    ${EMPTY}    ${controller_index}

Return ConnnectionID
    [Documentation]    Returns the connection of any host. Defaults to controller
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}
    ${conn_id}    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    [Return]    ${conn_id}

Copy Backup Directory To Test VM
    [Arguments]    ${host}=${CONTROLLER}
    ${new_dir}    Set Variable    ${BKP_DIR}${host}
    Empty Directory    ${new_dir}
    Remove Directory    ${new_dir}
    ${connections}    Return ConnnectionID
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Directory Should Exist    ${WORKSPACE}/${BUNDLEFOLDER}/daexim
    SSHLibrary.Get Directory    ${WORKSPACE}/${BUNDLEFOLDER}/daexim    ${new_dir}
    SSHLibrary.Close Connection
    ${output}    OperatingSystem.List Files In Directory    ${new_dir}
    Log    ${output}
    ${fl}     OperatingSystem.Get File     ${new_dir}/${BKP_DATA_FILE}
    Log     ${fl}

Copy Test VM Backup Directory To The Controller Zip
    [Arguments]    ${host}
    Log    ${host}
    @{connections}    Login To BVC Controller Hosts
    ${folder_location}    Set Variable    /tmp/Backup${host}
    ${size}    Get Length    ${connections}
    : FOR    ${index}    IN RANGE    ${size}
    \    SSHLibrary.Switch Connection    @{connections}[${index}]
    \    Execute SSH Command Expect Success    .    sudo rm -rf ${TEMP_DAEXIM}    @{connections}[${index}]
    \    SSHLibrary.Put Directory    ${folder_location}    ${TEMP_DAEXIM}
    \    Execute SSH Command Expect Success    .    sudo rm -rf ${DAEXIM_LOCATION}    @{connections}[${index}]
    \    Execute SSH Command Expect Success    .    sudo cp -r ${TEMP_DAEXIM} ${BVC_HOME}/controller/    @{connections}[${index}]
    \    Execute SSH Command Expect Success    .    sudo chown -R $USER:$USER ${DAEXIM_LOCATION}    @{connections}[${index}]
    \    ${ouput}    Execute SSH Command Expect Success    .     sudo ls -lart ${DAEXIM_LOCATION}    @{connections}[${index}]
    \    Log    ${ouput}
    \    ${file}    Execute SSH Command Expect Success    .    sudo cat ${DAEXIM_LOCATION}/${BKP_DATA_FILE}    @{connections}[${index}]
    \    Log    ${file}
    Logout Of BVC Controller Hosts    @{connections}    # Closes the SSH session

Copy Test VM Backup Directory To The Controller Packaging
    [Arguments]    ${host}
    Log    ${host}
    @{connections}    Login To BVC Controller Hosts
    ${folder_location}    Set Variable    /tmp/Backup${host}
    ${size}    Get Length    ${connections}
    : FOR    ${index}    IN RANGE    ${size}
    \    SSHLibrary.Switch Connection    @{connections}[${index}]
    \    Execute SSH Command Expect Success    .    sudo rm -rf ${TEMP_DAEXIM}    @{connections}[${index}]
    \    SSHLibrary.Put Directory    ${folder_location}    ${TEMP_DAEXIM}
    \    Execute SSH Command Expect Success    .    sudo -u brocade rm -rf ${DAEXIM_LOCATION}    @{connections}[${index}]
    \    Execute SSH Command Expect Success    .    sudo chown -R brocade:brocade ${TEMP_DAEXIM}    @{connections}[${index}]
    \    Execute SSH Command Expect Success    .    sudo -u brocade cp -r ${TEMP_DAEXIM} ${BVC_HOME}/controller/    @{connections}[${index}]
    \    ${ouput}    Execute SSH Command Expect Success    .     sudo -u brocade ls -lart ${DAEXIM_LOCATION}    @{connections}[${index}]
    \    Log    ${ouput}
    \    ${file}    Execute SSH Command Expect Success    .    sudo cat ${DAEXIM_LOCATION}/${BKP_DATA_FILE}    @{connections}[${index}]
    \    Log    ${file}
    Logout Of BVC Controller Hosts    ${connections}

Collect Support Diags
    [Documentation]    Create and copy the support diags
    # The actual job of create and copy is done by 'Create Support Diag File'
    @{connections}    Login To BVC Controller Hosts    # Starts the SSH session with the host
    Create Support Diag File    @{connections}    # Get Support Diag zip file from controller
    Logout Of BVC Controller Hosts    @{connections}    # Closes the SSH session

Mount Netconf Devices
    [Documentation]    Mount a netconf device
    [Arguments]    ${input_file}    ${end_point}
    ${JSON1}    OperatingSystem.Get File    ${input_file}
    ${body}    To Json    ${JSON1}
    @{host_list}    Create Controller List
    : FOR    ${host}    IN    @{host_list}
    \    Wait Until Keyword Succeeds    120 seconds    5 seconds    Do Controller Put Expect Success    ${NETCONF_MOUNT_URL}${end_point}    ${body}    ${host}

Delete Config Database
    [Documentation]   Delete config inventory on a host(s). Defaults to topology netconf url
    [Arguments]    ${url}=${TOPO_CONF_URL}
    @{host_list}    Create Controller List
    : FOR    ${host}    IN    @{host_list}
    \    Do Controller Delete    ${url}    ${host}

Delete Inventory Config Database
    [Documentation]   Delete config inventory on a host(s). Defaults to topology netconf url
    [Arguments]    ${url}=${NODE_INVENTORY_CONFIG_URL}
    @{host_list}    Create Controller List
    : FOR    ${host}    IN    @{host_list}
    \    Do Controller Delete    ${url}    ${host}

Verify Netconf Mount
    [Documentation]    Verify Netconf Mount Point
    [Arguments]    ${end_point}    ${def_port}=1830
    @{host_list}    Create Controller List
    : FOR    ${host}    IN    @{host_list}
    \    ${resp}    Do Controller Get    ${NETCONF_TOPOLOGY_URL}${end_point}    ${host}
    \    ${output}    Set Variable     ${resp[0].json()}
    \    Log     ${output}
    \    ${def_port}    Convert To String     ${def_port}
    \    ${endpoint}     Get From Dictionary     ${output['node'][0]}    node-id
    \    ${port}     Get From Dictionary     ${output['node'][0]}    netconf-node-topology:port
    \    ${port}     Convert To String     ${port}
    \    Should Be Equal    ${endpoint}    ${end_point}
    \    Should Be Equal    ${port}    ${def_port}

Pick A Random Host
    [Documentation]    Pick a Random host in a cluster
    ${host}    Pick A Random Host IP
    ${index}    Login To Host    ${host}    ${CONTROLLER_USER}    ${LOGIN_METHOD}    ${CONTROLLER_AUTH_ARG}    ${ID_RSA_KEYSTORE_PASS}
    [Return]    ${index}

Pick A Random Host IP
    [Documentation]    Pick a Random host IP from a host_list
    @{host_list}    Create Controller List
    ${size}    Get Length    ${host_list}
    ${host}    Run Keyword If     ${size} > 1    Pick A Random Cluster IP    @{host_list}    ELSE    Get From List    ${host_list}    0
    [Return]    ${host}

Pick A Random Cluster IP
    [Arguments]    @{host_list}
    ${random index}    Generate Random String    1    012
    ${host_ip}    Set Variable    @{host_list}[${random index}]
    [Return]    ${host_ip}

Change File String
    [Documentation]    Read a Json file and change the contents
    [Arguments]    ${file_dir}=${BKP_DIR}    ${line_to_replace}=${TARGET_LINE}    ${modified_line}=${LEGAL_CHANGE}    ${input_file}=${BKP_DATA_FILE}    ${previous_controller}=${CONTROLLER}
    ${new_dir}    Set Variable    ${file_dir}${CONTROLLER}
    ${old_dir}    Set Variable    ${file_dir}${previous_controller}
    Delete A Directory    ${new_dir}
    ${Conn}    Login To Multiple Hosts    localhost
    Execute SSH Command Expect Success    .    cp -r ${old_dir} ${new_dir}    ${Conn}
    Execute SSH Command Expect Success    ${new_dir}    sed -i 's/${line_to_replace}/${modified_line}/g' ${input_file}    ${Conn}
    ${file}    OperatingSystem.Get File    ${new_dir}/${input_file}
    Log    ${file}
    Logout Of SSH Hosts    ${Conn}
    [Return]    ${new_dir}

Setup Cluster Environment
    [Documentation]    Setup Cluster Suite Variables For A Given Test Case
    [Arguments]    ${controller}    ${controller1}    ${controller2}    ${controller_user}    ${controller_hostlist}
    Set Suite Variable    ${CONTROLLER}    ${controller}
    Set Suite Variable    ${CONTROLLER_USER}    ${controller_user}
    Set Suite Variable    ${CONTROLLER_HOST_LIST}    ${controller_hostlist}
    Set Suite Variable    ${CONTROLLER1}    ${controller1}
    Set Suite Variable    ${CONTROLLER2}    ${controller2}

Setup Single Node Environment
    [Documentation]    Setup Single Node Environment
    [Arguments]    ${controller}    ${controller_user}
    Set Suite Variable    ${CONTROLLER}    ${controller}
    Set Suite Variable    ${CONTROLLER_USER}    ${controller_user}

Setup Environment for Backup Testcases
    ${controller_list}    Get Variable Value    ${CONTROLLER_HOST_LIST1}     SINGLE_NODE
    ${status}    Run Keyword And Return Status    Should Contain    ${controller_list}    SINGLE_NODE
    Log    ${status}
    Run Keyword If     ${status}    Setup Single Node Environment    ${CONTROLLER1}    ${CONTROLLER_USER}    ELSE    Setup Cluster Environment    ${CONTROLLER01}    ${CONTROLLER11}    ${CONTROLLER21}    ${CONTROLLER_USER1}    ${CONTROLLER_HOST_LIST1}

Setup Environment for Restore Testcases
    ${controller_list}    Get Variable Value    ${CONTROLLER_HOST_LIST2}     SINGLE_NODE
    ${status}    Run Keyword And Return Status    Should Contain    ${controller_list}    SINGLE_NODE
    Log    ${status}
    Run Keyword If     ${status}    Setup Single Node Environment    ${CONTROLLER2}    ${CONTROLLER_USER}    ELSE    Setup Cluster Environment    ${CONTROLLER02}    ${CONTROLLER12}    ${CONTROLLER22}    ${CONTROLLER_USER2}    ${CONTROLLER_HOST_LIST2}

Delete File On The TestVM Backup Directory
    [Documentation]    Delete a given a file on backup directory on Test VM
    [Arguments]    ${file_dir}=${BKP_DIR}    ${file}=${BKP_MODEL_FILE}     ${previous_controller}=${CONTROLLER}
    ${new_dir}    Set Variable    ${file_dir}${CONTROLLER}
    ${old_dir}    Set Variable    ${file_dir}${previous_controller}
    Delete A Directory    ${new_dir}
    ${Conn}    Login To Multiple Hosts    localhost
    Execute SSH Command Expect Success    .    cp -r ${old_dir} ${new_dir}    ${Conn}
    Execute SSH Command Expect Success    ${new_dir}    sudo rm -rf ${file}    ${Conn}
    ${output}    Execute SSH Command Expect Success    ${new_dir}    ls -lart    ${Conn}
    Log    ${output}
    Logout Of SSH Hosts    ${Conn}
    [Return]    ${new_dir}

Post TestApp Data on A Host
    [Documentation]    Posts data on TestApp model installed on Previous Controller
    [Arguments]    ${host}=${CONTROLLER}    ${file}=${TESTAPP_BEFORE_JSON}
    ${JSON1}    OperatingSystem.Get File    ${file}
    ${body}    To Json    ${JSON1}
    Wait Until Keyword Succeeds    60 seconds    10 seconds    Do Controller Post Expect Success    ${TESTAPP_URL}    ${body}    ${host}

Rename Shard
    [Documentation]    Convert inventory shard to a new one
    @{connections}    Login To BVC Controller Hosts
    Stop Brocade Vyatta Controller    ${BVC_HOME}    120    False    ${connections}
    Execute SSH Command    ${BVC_HOME}/controller/configuration/initial   ${RENAME_SHARD_COMMAND}    @{connections}
    Start Brocade Vyatta Controller    ${BVC_HOME}    ${connections}
    Logout Of BVC Controller Hosts    ${connections}

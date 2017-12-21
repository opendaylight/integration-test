*** Settings ***
Library           OperatingSystem
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Resource          ClusterManagement.robot
Resource          ../variables/daexim/DaeximVariables.robot
Resource          ../variables/Variables.robot
Resource          SSHKeywords.robot

*** Keywords ***
Verify Export Files
    [Arguments]    ${host_index}
    [Documentation]    Verify if the backedup files are present in the controller
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${cfg}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_DATA_FILE}    ${host_index}
    Builtin.Log    ${cfg}
    Builtin.Should Match Regexp    ${cfg}    .*${EXP_DATA_FILE}
    ${mdl}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}    ${host_index}
    Builtin.Log    ${mdl}
    Builtin.Should Match Regexp    ${mdl}    .*${MODELS_FILE}
    ${opr}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_OPER_FILE}    ${host_index}
    Builtin.Log    ${opr}
    Builtin.Should Match Regexp    ${opr}    .*${EXP_OPER_FILE}

Verify Export Files Not Present
    [Arguments]    ${host_index}
    [Documentation]    Verify if the backedup files are not present in the controller
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${cfg}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_DATA_FILE}    ${host_index}
    Builtin.Log    ${cfg}
    Builtin.Should Not Match Regexp    ${cfg}    .*${EXP_DATA_FILE}
    ${mdl}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}    ${host_index}
    Builtin.Log    ${mdl}
    Builtin.Should Not Match Regexp    ${mdl}    .*${MODELS_FILE}
    ${opr}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_OPER_FILE}    ${host_index}
    Builtin.Log    ${opr}
    Builtin.Should Not Match Regexp    ${opr}    .*${EXP_OPER_FILE}

Cleanup The Export Files
    [Arguments]    ${host_index}
    [Documentation]    Verify if the export directory exists and delete the files if needed
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    Builtin.Run Keyword And Ignore Error    ClusterManagement.Delete_And_Check_Member_List_Or_All    ${TOPOLOGY_URL}    ${host_index}
    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim;clear    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim;clear    ${host_index}
    ${output}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}    ${host_index}
    Builtin.Log    ${output}
    Builtin.Should Not Match Regexp    ${output}    daexim

Verify Export Status
    [Arguments]    ${status}    ${controller_index}
    [Documentation]    Verify export status is as expected
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${STATUS_EXPORT_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Verify Export Status Message    ${status}    ${response_json}

Verify Scheduled Export Timestamp
    [Arguments]    ${controller_index}    ${time}
    [Documentation]    Verify export timestamp is as expected
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${STATUS_EXPORT_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Builtin.Should Match Regexp    ${response_json}    .*"run-at": "${time}"

Verify Export Status Message
    [Arguments]    ${status}    ${output}
    [Documentation]    Verify export restconf response message is as expected
    Builtin.Should Match Regexp    ${output}    "status": "${status}"
    Builtin.Run Keyword If    "${status}" == "initial" or "${status}" == "scheduled" or "${status}" == "skipped"    Verify Json Files Not Present    ${output}
    ...    ELSE    Verify Json Files Present    ${output}

Verify Json Files Present
    [Arguments]    ${output}    ${config_json}=${EXP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${EXP_OPER_FILE}
    [Documentation]    Verify if the json files are generated after a export/export
    Builtin.Should Match Regexp    ${output}    .*${config_json}
    Builtin.Should Match Regexp    ${output}    .*${models_json}
    Builtin.Should Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Found all Json Files

Verify Json Files Not Present
    [Arguments]    ${output}    ${config_json}=${EXP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${EXP_OPER_FILE}
    [Documentation]    Verify if the json files are not present under the daexim folder
    Builtin.Should Not Match Regexp    ${output}    .*${config_json}
    Builtin.Should Not Match Regexp    ${output}    .*${models_json}
    Builtin.Should Not Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Did not Find all Json Files

Schedule Export
    [Arguments]    ${controller_index}    ${TIME}=500    ${exclude}=${FALSE}    ${MODULE}=${EMPTY}    ${STORE}=${EMPTY}    ${FLAG}=false
    [Documentation]    Schedule Export job
    ${file}    Builtin.Set Variable If    ${exclude}    ${EXPORT_EXCLUDE_FILE}    ${EXPORT_FILE}
    ${JSON1}    OperatingSystem.Get File    ${file}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Cleanup The Export Files    ${controller_index}
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${SCHEDULE_EXPORT_URL}    ${JSON2}    ${controller_index}
    Builtin.Log    ${response_json}

Schedule Exclude Export
    [Arguments]    ${controller_index}    ${store}    ${module}
    [Documentation]    Schedules a export with exclude option. Returns the file that has the excluded export.
    ${controller_index}    Builtin.Convert To Integer    ${controller_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${controller_index}
    Schedule Export    ${controller_index}    500    ${TRUE}    ${module}    ${store}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    Verify Export Status    complete    ${controller_index}
    Verify Export Files    ${controller_index}
    Copy Export Directory To Test VM    ${host}
    ${export_file}    Builtin.Set Variable If    '${store}' == 'operational'    ${EXP_OPER_FILE}    ${EXP_DATA_FILE}
    ${file_path}    OperatingSystem.Join Path    ${EXP_DIR}${host}    ${export_file}
    [Return]    ${file_path}

Cancel Export
    [Arguments]    ${controller_index}
    [Documentation]    Cancel the export job
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${CANCEL_EXPORT_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}

Return ConnnectionID
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}
    [Documentation]    Returns the connection of any host. Defaults to controller
    ${conn_id}    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    SSHKeywords.Flexible SSH Login    ${user}    ${password}
    [Return]    ${conn_id}

Cleanup Directory
    [Arguments]    ${dir}
    [Documentation]    Cleans up the given directory if it exists
    OperatingSystem.Empty Directory    ${dir}
    OperatingSystem.Remove Directory    ${dir}

Copy Export Directory To Test VM
    [Arguments]    ${host}
    [Documentation]    This keyword copies the daexim folder genereated in the controller to robot vm. This is done to editing if needed on the json files
    ${new_dir}    Builtin.Set Variable    ${EXP_DIR}${host}
    ${directory_exist}    Builtin.Run Keyword And Return Status    OperatingSystem.Directory Should Exist    ${new_dir}
    Builtin.Run Keyword If    ${directory_exist}    Cleanup Directory    ${new_dir}
    ${connections}    Return ConnnectionID    ${host}
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Directory Should Exist    ${WORKSPACE}/${BUNDLEFOLDER}/daexim
    SSHLibrary.Get Directory    ${WORKSPACE}/${BUNDLEFOLDER}/daexim    ${new_dir}
    SSHLibrary.Close Connection
    ${output}    OperatingSystem.List Files In Directory    ${new_dir}
    Builtin.Log    ${output}
    ${fl}    OperatingSystem.Get File    ${new_dir}/${EXP_DATA_FILE}
    Builtin.Log    ${fl}

Copy Config Data To Controller
    [Arguments]    ${host_index}
    [Documentation]    This keyword copies the daexim folder under variables folder to the Controller
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${host_index}
    ${connections}    Return ConnnectionID    ${host}
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Put Directory    ${CURDIR}/${DAEXIM_DATA_DIRECTORY}    ${WORKSPACE}/${BUNDLEFOLDER}/    mode=664
    SSHLibrary.Close Connection

Mount Netconf Endpoint
    [Arguments]    ${endpoint}    ${host_index}
    [Documentation]    Mount a netconf endpoint
    ${ENDPOINT}    Builtin.Set Variable    ${endpoint}
    ${JSON1}    OperatingSystem.Get File    ${CURDIR}/${NETCONF_PAYLOAD_JSON}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Builtin.Log    ${JSON2}
    ${resp}    ClusterManagement.Put_As_Json_To_Member    ${NETCONF_MOUNT_URL}${endpoint}    ${JSON2}    ${host_index}
    Builtin.Log    ${resp}

Fetch Status Information From Netconf Endpoint
    [Arguments]    ${endpoint}    ${host_index}
    [Documentation]    This keyword fetches netconf endpoint information
    ${resp}    ClusterManagement.Get_From_Member    ${NTCF_TPLG_OPR_URL}${endpoint}    ${host_index}
    ${output1}    Builtin.Set Variable    ${resp}
    ${output}    RequestsLibrary.To Json    ${output1}
    Builtin.Log    ${output}
    ${status}    Collections.Get From Dictionary    ${output['node'][0]}    netconf-node-topology:connection-status
    [Return]    ${status}    ${output}

Verify Status Information
    [Arguments]    ${endpoint}    ${host_index}    ${itr}=50
    [Documentation]    Verify if a netconf endpoint status is connected by running in a loop
    : FOR    ${i}    IN RANGE    ${itr}
    \    ${sts}    ${op}    Fetch Status Information From Netconf Endpoint    ${endpoint}    ${host_index}
    \    Builtin.Log    ${i}
    \    Builtin.Exit For Loop If    "${sts}" == "${NTCF_OPR_STATUS}"
    [Return]    ${sts}    ${op}

Verify Netconf Mount
    [Arguments]    ${endpoint}    ${host_index}
    [Documentation]    Verify if a netconf endpoint is mounted
    ${sts1}    ${output}    Verify Status Information    ${endpoint}    ${host_index}
    ${ep}    Collections.Get From Dictionary    ${output['node'][0]}    node-id
    ${port}    Collections.Get From Dictionary    ${output['node'][0]}    netconf-node-topology:port
    ${port}    Builtin.Convert To String    ${port}
    Builtin.Should Be Equal    ${endpoint}    ${ep}
    Builtin.Should Be Equal    ${port}    ${NETCONF_PORT}

Schedule Import
    [Arguments]    ${host_index}    ${result}=true    ${reason}=${EMPTY}    ${mdlflag}=${MDL_DEF_FLAG}    ${strflag}=${STR_DEF_FLAG}
    [Documentation]    Schedule an Import API
    ${MODELFLAG}    Builtin.Set Variable    ${mdlflag}
    ${STOREFLAG}    Builtin.Set Variable    ${strflag}
    ${JSON1}    OperatingSystem.Get File    ${CURDIR}/${IMPORT_PAYLOAD}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Builtin.Log    ${JSON2}
    ${resp}    Builtin.Wait Until Keyword Succeeds    120 seconds    10 seconds    ClusterManagement.Post_As_Json_To_Member    ${IMPORT_URL}    ${JSON2}
    ...    ${host_index}
    Builtin.Log    ${resp}
    Builtin.Should Match Regexp    ${resp}    .*"result": ${result}
    Builtin.Run Keyword If    "${reason}" != "${EMPTY}"    Builtin.Should Match Regexp    ${response_json}    .*"reason":"${reason}

Cleanup Cluster Export Files
    [Arguments]    ${host1_index}=${FIRST_CONTROLLER_INDEX}    ${host2_index}=${SECOND_CONTROLLER_INDEX}    ${host3_index}=${THIRD_CONTROLLER_INDEX}
    [Documentation]    This keyword cleansup export files of a cluster
    DaeximKeywords.Cleanup The Export Files    ${host1_index}
    DaeximKeywords.Cleanup The Export Files    ${host2_index}
    DaeximKeywords.Cleanup The Export Files    ${host3_index}

*** Settings ***
Library     OperatingSystem
Library     SSHLibrary
Library     Collections
Library     RequestsLibrary
Resource    ClusterManagement.robot
Resource    ../variables/daexim/DaeximVariables.robot
Resource    ../variables/Variables.robot
Resource    SSHKeywords.robot
Resource    Utils.robot


*** Keywords ***
Verify Export Files
    [Documentation]    Verify if the backedup files are present in the controller
    [Arguments]    ${host_index}
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${cfg}    ClusterManagement.Run Bash Command On Member
    ...    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_DATA_FILE}
    ...    ${host_index}
    Builtin.Log    ${cfg}
    Builtin.Should Match Regexp    ${cfg}    .*${EXP_DATA_FILE}
    ${mdl}    ClusterManagement.Run Bash Command On Member
    ...    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}
    ...    ${host_index}
    Builtin.Log    ${mdl}
    Builtin.Should Match Regexp    ${mdl}    .*${MODELS_FILE}
    ${opr}    ClusterManagement.Run Bash Command On Member
    ...    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_OPER_FILE}
    ...    ${host_index}
    Builtin.Log    ${opr}
    Builtin.Should Match Regexp    ${opr}    .*${EXP_OPER_FILE}

Verify Export Files Not Present
    [Documentation]    Verify if the backedup files are not present in the controller
    [Arguments]    ${host_index}
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${cfg}    ClusterManagement.Run Bash Command On Member
    ...    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_DATA_FILE}
    ...    ${host_index}
    Builtin.Log    ${cfg}
    Builtin.Should Not Match Regexp    ${cfg}    .*${EXP_DATA_FILE}
    ${mdl}    ClusterManagement.Run Bash Command On Member
    ...    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}
    ...    ${host_index}
    Builtin.Log    ${mdl}
    Builtin.Should Not Match Regexp    ${mdl}    .*${MODELS_FILE}
    ${opr}    ClusterManagement.Run Bash Command On Member
    ...    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_OPER_FILE}
    ...    ${host_index}
    Builtin.Log    ${opr}
    Builtin.Should Not Match Regexp    ${opr}    .*${EXP_OPER_FILE}

Cleanup The Export Files
    [Documentation]    Verify if the export directory exists and delete the files if needed
    [Arguments]    ${host_index}
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    Builtin.Run Keyword And Ignore Error
    ...    ClusterManagement.Delete And Check Member List Or All
    ...    ${TOPOLOGY_URL}
    ...    ${host_index}
    ${output1}    Builtin.Run Keyword and IgnoreError
    ...    ClusterManagement.Run Bash Command On Member
    ...    sudo rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim;clear
    ...    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError
    ...    ClusterManagement.Run Bash Command On Member
    ...    rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim;clear
    ...    ${host_index}
    ${output}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}    ${host_index}
    Builtin.Log    ${output}
    Builtin.Should Not Match Regexp    ${output}    daexim

Verify Export Status
    [Documentation]    Verify export status is as expected
    [Arguments]    ${status}    ${controller_index}
    ${response_json}    ClusterManagement.Post As Json To Member
    ...    ${STATUS_EXPORT_URL}
    ...    ${EMPTY}
    ...    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Verify Export Status Message    ${status}    ${response_json}

Verify Scheduled Export Timestamp
    [Documentation]    Verify export timestamp is as expected
    [Arguments]    ${controller_index}    ${time}
    ${response_json}    ClusterManagement.Post As Json To Member
    ...    ${STATUS_EXPORT_URL}
    ...    ${EMPTY}
    ...    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Builtin.Should Match Regexp    ${response_json}    .*"run-at": "${time}"

Verify Export Status Message
    [Documentation]    Verify export restconf response message is as expected
    [Arguments]    ${status}    ${output}
    Builtin.Should Match Regexp    ${output}    "status": "${status}"
    IF    "${status}" == "initial" or "${status}" == "scheduled" or "${status}" == "skipped"
        Verify Json Files Not Present    ${output}
    ELSE
        Verify Json Files Present    ${output}
    END

Verify Json Files Present
    [Documentation]    Verify if the json files are generated after a export/export
    [Arguments]    ${output}    ${config_json}=${EXP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${EXP_OPER_FILE}
    Builtin.Should Match Regexp    ${output}    .*${config_json}
    Builtin.Should Match Regexp    ${output}    .*${models_json}
    Builtin.Should Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Found all Json Files

Verify Json Files Not Present
    [Documentation]    Verify if the json files are not present under the daexim folder
    [Arguments]    ${output}    ${config_json}=${EXP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${EXP_OPER_FILE}
    Builtin.Should Not Match Regexp    ${output}    .*${config_json}
    Builtin.Should Not Match Regexp    ${output}    .*${models_json}
    Builtin.Should Not Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Did not Find all Json Files

Schedule Export
    [Documentation]    Schedule Export job
    [Arguments]    ${controller_index}    ${time}=500    ${exclude}=${FALSE}    ${module}=${EMPTY}    ${store}=${EMPTY}    ${flag}=false
    ...    ${include}=${FALSE}
    IF    ${include}
        ${file}    Builtin.Set Variable    ${EXPORT_INCLUDE_FILE}
    ELSE
        ${file}    Builtin.Set Variable If    ${exclude}    ${EXPORT_EXCLUDE_FILE}    ${EXPORT_FILE}
    END
    ${json}    OperatingSystem.Get File    ${file}
    ${json}    Builtin.Replace Variables    ${json}
    Cleanup The Export Files    ${controller_index}
    ${response_json}    ClusterManagement.Post As Json To Member
    ...    ${SCHEDULE_EXPORT_URL}
    ...    ${json}
    ...    ${controller_index}
    Builtin.Log    ${response_json}

Schedule Exclude Export
    [Documentation]    Schedules a export with exclude option. Returns the file that has the excluded export.
    [Arguments]    ${controller_index}    ${store}    ${module}
    ${controller_index}    Builtin.Convert To Integer    ${controller_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${controller_index}
    Schedule Export    ${controller_index}    500    ${TRUE}    ${module}    ${store}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    Verify Export Status    complete    ${controller_index}
    Verify Export Files    ${controller_index}
    Copy Export Directory To Test VM    ${host}
    ${export_file}    Builtin.Set Variable If    '${store}' == 'operational'    ${EXP_OPER_FILE}    ${EXP_DATA_FILE}
    ${file_path}    OperatingSystem.Join Path    ${EXP_DIR}${host}    ${export_file}
    RETURN    ${file_path}

Schedule Include Export
    [Documentation]    Schedules a export with include option. Returns the file that has the included export.
    [Arguments]    ${controller_index}    ${store}    ${module}=${EMPTY}    ${exclude}=${FALSE}
    ${controller_index}    Builtin.Convert To Integer    ${controller_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${controller_index}
    ${time}    Builtin.Set Variable    500
    ${file}    Builtin.Set Variable If    ${exclude}    ${EXPORT_INCEXCLUDE_FILE}    ${EXPORT_INCLUDE_FILE}
    ${json}    OperatingSystem.Get File    ${file}
    ${json}    Builtin.Replace Variables    ${json}
    Cleanup The Export Files    ${controller_index}
    ${response_json}    ClusterManagement.Post As Json To Member
    ...    ${SCHEDULE_EXPORT_URL}
    ...    ${json}
    ...    ${controller_index}
    Builtin.Log    ${response_json}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    Verify Export Status    complete    ${controller_index}
    Verify Export Files    ${controller_index}
    Copy Export Directory To Test VM    ${host}
    ${export_file}    Builtin.Set Variable If    '${store}' == 'operational'    ${EXP_OPER_FILE}    ${EXP_DATA_FILE}
    ${file_path}    OperatingSystem.Join Path    ${EXP_DIR}${host}    ${export_file}
    RETURN    ${file_path}

Cancel Export
    [Documentation]    Cancel the export job
    [Arguments]    ${controller_index}
    ${response_json}    ClusterManagement.Post As Json To Member
    ...    ${CANCEL_EXPORT_URL}
    ...    ${EMPTY}
    ...    ${controller_index}
    Builtin.Log    ${response_json}

Return ConnnectionID
    [Documentation]    Returns the connection of any host. Defaults to controller
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}
    ${conn_id}    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    SSHKeywords.Flexible SSH Login    ${user}    ${password}
    RETURN    ${conn_id}

Cleanup Directory
    [Documentation]    Cleans up the given directory if it exists
    [Arguments]    ${dir}
    OperatingSystem.Empty Directory    ${dir}
    OperatingSystem.Remove Directory    ${dir}

Copy Export Directory To Test VM
    [Documentation]    This keyword copies the daexim folder genereated in the controller to robot vm. This is done to editing if needed on the json files
    [Arguments]    ${host}
    ${new_dir}    Builtin.Set Variable    ${EXP_DIR}${host}
    ${directory_exist}    Builtin.Run Keyword And Return Status    OperatingSystem.Directory Should Exist    ${new_dir}
    IF    ${directory_exist}    Cleanup Directory    ${new_dir}
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
    [Documentation]    This keyword copies the daexim folder under variables folder to the Controller
    [Arguments]    ${host_index}
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${host_index}
    ${connections}    Return ConnnectionID    ${host}
    SSHLibrary.Switch Connection    ${connections}
    ${dictionary}=    CompareStream.Set_Variable_If_At_Least_Scandium    ${DAEXIM_DATA_DIRECTORY_SCANDIUM}    ${DAEXIM_DATA_DIRECTORY_CALCIUM}
    SSHLibrary.Put Directory    ${CURDIR}/${dictionary}   ${WORKSPACE}/${BUNDLEFOLDER}/    mode=664
    SSHLibrary.Close Connection

Mount Netconf Endpoint
    [Documentation]    Mount a netconf endpoint
    [Arguments]    ${endpoint}    ${host_index}
    ${ENDPOINT}    Builtin.Set Variable    ${endpoint}
    ${json}    OperatingSystem.Get File    ${CURDIR}/${NETCONF_PAYLOAD_JSON}
    ${json}    Builtin.Replace Variables    ${json}
    Builtin.Log    ${json}
    ${resp}    ClusterManagement.Put As Json To Member    ${NETCONF_NODE_URL}=${endpoint}    ${json}    ${host_index}
    Builtin.Log    ${resp}

Fetch Status Information From Netconf Endpoint
    [Documentation]    This keyword fetches netconf endpoint information
    [Arguments]    ${endpoint}    ${host_index}
    ${resp}    ClusterManagement.Get From Member    ${NETCONF_NODE_URL}=${endpoint}    ${host_index}
    ${output1}    Builtin.Set Variable    ${resp}
    ${output}    Utils.Json Parse From String    ${output1}
    Builtin.Log    ${output}
    ${node}    Collections.Get From Dictionary    ${output['network-topology:node'][0]}    netconf-node-topology:netconf-node
    ${status}    Collections.Get From Dictionary    ${node}    connection-status
    RETURN    ${status}    ${output}

Verify Status Information
    [Documentation]    Verify if a netconf endpoint status is connected by running in a loop
    [Arguments]    ${endpoint}    ${host_index}    ${itr}=50
    FOR    ${i}    IN RANGE    ${itr}
        ${sts}    ${op}    Fetch Status Information From Netconf Endpoint    ${endpoint}    ${host_index}
        Builtin.Log    ${i}
        IF    "${sts}" == "${NTCF_OPR_STATUS}"            BREAK
    END
    RETURN    ${sts}    ${op}

Verify Netconf Mount
    [Documentation]    Verify if a netconf endpoint is mounted
    [Arguments]    ${endpoint}    ${host_index}
    ${sts1}    ${output}    Verify Status Information    ${endpoint}    ${host_index}
    ${ep}    Collections.Get From Dictionary    ${output['network-topology:node'][0]}    node-id
    ${node}    Collections.Get From Dictionary    ${output['network-topology:node'][0]}    netconf-node-topology:netconf-node
    ${port}    Collections.Get From Dictionary    ${node}    port
    ${port}    Builtin.Convert To String    ${port}
    Builtin.Should Be Equal    ${endpoint}    ${ep}
    Builtin.Should Be Equal    ${port}    ${NETCONF_PORT}

Schedule Import
    [Documentation]    Schedule an Import API
    [Arguments]    ${host_index}    ${result}=true    ${reason}=${EMPTY}    ${mdlflag}=${MDL_DEF_FLAG}    ${strflag}=${STR_DEF_FLAG}
    ${modelflag}    Builtin.Set Variable    ${mdlflag}
    ${storeflag}    Builtin.Set Variable    ${strflag}
    ${json}    OperatingSystem.Get File    ${CURDIR}/${IMPORT_PAYLOAD}
    ${json}    Builtin.Replace Variables    ${json}
    Builtin.Log    ${json}
    ${resp}    Builtin.Wait Until Keyword Succeeds
    ...    120 seconds
    ...    10 seconds
    ...    ClusterManagement.Post As Json To Member
    ...    ${IMPORT_URL}
    ...    ${json}
    ...    ${host_index}
    Builtin.Log    ${resp}
    Builtin.Should Match Regexp    ${resp}    .*"result": ${result}
    IF    "${reason}" != "${EMPTY}"
        Builtin.Should Match Regexp    ${response_json}    .*"reason":"${reason}
    END

Cleanup Cluster Export Files
    [Documentation]    This keyword cleansup export files of a cluster
    [Arguments]    ${member_index_list}=${EMPTY}
    ${index_list}    List Indices Or All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        DaeximKeywords.Cleanup The Export Files    ${index}
    END

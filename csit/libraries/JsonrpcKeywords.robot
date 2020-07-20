*** Settings ***
Library           Collections
Library           json
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          ClusterManagement.robot
Resource          NexusKeywords.robot
Resource          TemplatedRequests.robot
Resource          Utils.robot
Resource          ../variables/jsonrpc/JsonrpcVariables.robot
Resource          ../variables/Variables.robot

*** Keywords ***
Install And Start Testtool
    [Documentation]     Download and start JSONRPC test tool
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    ${filename}=    NexusKeywords.Deploy_Test_Tool    jsonrpc    test-tool     suffix=${EMPTY}
    Start Test Tool     ${filename}

Start Test Tool
    [Documentation]    Start JSONRPC test tool
    [Arguments]    ${filename}    ${rpc_endpoint}=${TESTTOOL_RPC_ENDPOINT}    ${governance_endpoint}=${TESTTOOL_GOV_ENDPOINT}
    ...    ${datastore_modules}=test-model,network-topology    ${datastore_endpoint}=${TESTTOOL_DATA_ENDPOINT}    ${java_options}=${TESTTOOL_JAVA_OPTIONS}
    ...    ${yang_directory}=/tmp
    ${tool_options}=     Builtin.Catenate    --governance    ${governance_endpoint}
    ${tool_options}=     Builtin.Catenate    --rpc    ${rpc_endpoint}    ${tool_options}
    ${tool_options}=     Builtin.Catenate    --datastore    ${datastore_endpoint}    ${tool_options}
    ${tool_options}=     Builtin.Catenate    --datastore-modules    ${datastore_modules}    ${tool_options}
    ${tool_options}=     Builtin.Catenate    --yang-directory    ${yang_directory}    ${tool_options}
    ${command}=    NexusKeywords.Compose_Full_Java_Command    ${java_options} -jar ${filename} ${tool_options}
    BuiltIn.Log    Running testtool: ${command}
    ${logfile}=    Utils.Get_Log_File_Name    testtool
    BuiltIn.Set_Suite_Variable    ${testtool_log}    ${logfile}
    ${testtool}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool}
    SSHLibrary.Write    ${command} >${logfile} 2>&1

Run Read Service Python Script on Controller Vm
    [Arguments]    ${host_index}=${FIRST_CONTROLLER_INDEX}    ${ub_system}=${FALSE}
    [Documentation]    This keyword installs pip,zmq,pyzmq and starts the read service on controller vm
    ${cmd}    Builtin.Set Variable If    ${ub_system}    ${UB_PIP}    ${CENTOS_PIP}
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${host_index}
    ${connections}    SSHKeywords.Open_Connection_To_ODL_System    ${host}
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Put File    ${READ_SERVICE_SCRIPT}    ${WORKSPACE}/${BUNDLEFOLDER}/    mode=664
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ${cmd}    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stdout}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install --upgrade pip    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stdout}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install zmq pyzmq    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stdout}
    ${module}    OperatingSystem.Get File    ${JSONRPCCONFIG_MODULE_JSON}
    ${data}    OperatingSystem.Get File    ${JSONRPCCONFIG_DATA_JSON}
    ${cmd}    Builtin.Set Variable    nohup python ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}'
    Log    ${cmd}
    ${stdout}    SSHLibrary.Write    echo | rm -rf nohup.out
    ${stdout}    SSHLibrary.Write    echo | nohup python ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}' &
    ${stdout}    SSHLibrary.Write    echo
    Log    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    cat nohup.out
    Log    ${stdout}
    SSHLibrary.Close_Connection

Mount Read Service Endpoint
    [Arguments]    ${controller_index}=${FIRST_CONTROLLER_INDEX}    ${file}=${READ_SERVICE_PEER_PAYLOAD}    ${endpoint}=${DEFAULT_ENDPOINT}
    [Documentation]    This keyword mounts an endpoint after starting service
    ${JSON1}    OperatingSystem.Get File    ${file}
    Log    ${JSON1}
    ${response_json}    ClusterManagement.Put_As_Json_To_Member    ${READ_SERVICE_PEER_PUT_URL}${endpoint}    ${JSON1}    ${controller_index}
    Builtin.Log    ${response_json}

Verify Data On Mounted Endpoint
    [Arguments]    ${controller_index}=${FIRST_CONTROLLER_INDEX}    ${endpoint}=${DEFAULT_ENDPOINT}
    [Documentation]    This keyword verifies if the data we get on the mount point is same as what we put
    ${resp}    ClusterManagement.Get_From_Member    ${READ_SERVICE_PEER_GET_1}${endpoint}${READ_SERVICE_PEER_GET_2}    ${controller_index}
    ${response_json}    Builtin.Convert To String    ${resp}
    Log    ${response_json}
    Verify Restconf Get On Mounted Endpoint    ${response_json}    ${READSERVICE_NAME}

Verify Restconf Get On Mounted Endpoint
    [Arguments]    ${output}    ${name}
    [Documentation]    This keyword parses restconf get of mountpoint
    Builtin.Should Match Regexp    ${output}    "name":"${name}"

Replace Endpoint Address
    [Arguments]   ${endpoint}    ${new_address}
    [Documentation]     Take endpoint URI, replace IP address in it (wildcard or loopback) with real IP address.
    ...     eg. zmq://0.0.0.0:11200?timeout=3000 => zmq://10.10.10.10:11200?timeout=3000
    ${result}=    String.Replace String     ${endpoint}     0.0.0.0     ${new_address}
    ${result}=    String.Replace String     ${result}     127.0.0.1     ${new_address}
    [Return]    ${result}

Initialize JSONRPC
    [Documentation]     Initialize JSONRPC extension in ODL, optionally configure it with external governance service.
    [Arguments]     ${remote_control}=${REMOTE_CONTROL_ENDPOINT}    ${governance}=${None}
    &{outer}=    Builtin.Create Dictionary
    &{data}=    Builtin.Create Dictionary
    Collections.Set To Dictionary    ${outer}    jsonrpc:config=${data}
    ${is_rc_set}=    Builtin.Run Keyword And Return Status    Should Not Be Equal    ${remote_control}    ${None}
    Run Keyword If	${is_rc_set}	Collections.Set To Dictionary    ${data}    who-am-i=${remote_control}
    ${is_gov_set}=    Builtin.Run Keyword And Return Status    Should Not Be Equal    ${governance}    ${None}
    Run Keyword If    ${is_gov_set}    Collections.Set To Dictionary    ${data}    governance-root=${governance}
    ${data}=    Json.Dumps    ${outer}
    TemplatedRequests.Put_As_Json_To_Uri    ${JSONRPC_CFG_DS_URI}      ${data}

Unconfigure JSONRPC
    [Documentation]     Unconfigure JSONRPC by removing whole configuration container from DS
    TemplatedRequests.Delete_From_Uri   uri=${JSONRPC_CFG_DS_URI}    additional_allowed_status_codes=${DELETED_STATUS_CODES}

Create Endpoint List
    [Arguments]    ${dict_to_set}    ${endpoints}    ${endpoint_type}=${EMPTY_STR}
    [Documentation]    Convert string specification of endpoint list into python list
    @{ep_list}=    Builtin.Create List
    @{parsed_list}=    String.Split String    ${endpoints}    separator=,
    FOR    ${endpoint}    IN    @{parsed_list}
        ${components}=    String.Split String    ${endpoint}    separator==
        ${current}=    Builtin.Create Dictionary
        ${uri}=    String.Remove String    ${components[1]}    "
        Collections.Set To Dictionary    ${current}    path=${components[0]}
        Collections.Set To Dictionary    ${current}    endpoint-uri=${uri}
        Collections.Append To List    ${ep_list}    ${current}
    END
    Collections.Set To Dictionary    ${dict_to_set}    ${endpoint_type}=${ep_list}

Mount Peer
    [Arguments]    ${name}    ${module_list}    ${config_endpoints}=${EMPTY}    ${op_endpoints}=${EMPTY}
    ...    ${rpc_endpoints}=${EMPTY}    ${notification_endpoints}=${EMPTY}    ${verify}=${True}
    [Documentation]    Mount service onto controller via JSONRPC using provided module list and endpoints.
    ...
    ...    Arguments
    ...
    ...    module_list - comma separated list of modules
    ...
    ...    config_endpoints,op_endpoints,rpc_endpoints,notification_endpoints - comma separated list of endpoints
    ...    in form of path=uri, eg. {}=zmq://127.0.0.1:12000
    &{outer}=    Builtin.Create Dictionary
    &{data}=    Builtin.Create Dictionary
    Collections.Set To Dictionary    ${outer}    configured-endpoints=${data}
    Collections.Set To Dictionary    ${data}    name=${name}
    @{modules}=    String.Split String    ${module_list}    ,
    Collections.Set To Dictionary    ${data}    modules=@{modules}
    Run Keyword Unless    '''${config_endpoints}'''=='''${EMPTY}'''    Create Endpoint List    ${data}    ${config_endpoints}    data-config-endpoints
    Run Keyword Unless    '''${op_endpoints}'''=='''${EMPTY}'''    Create Endpoint List    ${data}    ${op_endpoints}    data-operational-endpoints
    Run Keyword Unless    '''${rpc_endpoints}'''=='''${EMPTY}'''    Create Endpoint List    ${data}    ${rpc_endpoints}    rpc-endpoints
    Run Keyword Unless    '''${notification_endpoints}'''=='''${EMPTY}'''    Create Endpoint List    ${data}    ${notification_endpoints}    notification-endpoints
    ${data}=    Json.Dumps    ${outer}
    ${uri}=    Builtin.Catenate    SEPARATOR=/    ${JSONRPC_MP_URI}    ${name}
    TemplatedRequests.Put_As_Json_To_Uri    ${uri}      ${data}
    Run Keyword If    ${verify}     Wait Until Keyword Succeeds    10 sec    5 sec    Verify Mountpoint Status    ${name}

Verify Mountpoint Status
    [Arguments]    ${name}    ${state}=mounted
    [Documentation]    Ensure mountpoint state is equal to given value (mounted/failed)
    ${uri}=    Builtin.Catenate    SEPARATOR=/    ${JSONRPC_OP_DS_URI}    actual-endpoints    ${name}
    ${resp}=    TemplatedRequests.Get_As_Json_From_Uri    ${uri}
    ${data}=    Json.Loads  ${resp}
    ${actual_state}=    Builtin.Get Variable Value    ${data['actual-endpoints'][0]['mount-status']}
    Should Be Equal    ${actual_state}    ${state}

Unmount Peer
    [Arguments]     ${peer}
    [Documentation]     Remove JSONRPC mountpoint by deleting entry from configured-endpoints list
    ${uri}=      Builtin.Catenate    SEPARATOR=/     ${JSONRPC_MP_URI}   ${peer}
    TemplatedRequests.Delete_From_Uri   uri=${uri}    additional_allowed_status_codes=${DELETED_STATUS_CODES}


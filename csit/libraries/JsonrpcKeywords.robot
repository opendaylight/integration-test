*** Settings ***
Library     OperatingSystem
Library     SSHLibrary
Library     Collections
Library     RequestsLibrary
Resource    ClusterManagement.robot
Resource    ../variables/jsonrpc/JsonrpcVariables.robot
Resource    ../variables/Variables.robot
Resource    SSHKeywords.robot
Resource    Utils.robot


*** Keywords ***
Run Read Service Python Script on Controller Vm
    [Documentation]    This keyword creates a new virtual environment, installs pyzmq & zmq and starts the read service on controller vm
    [Arguments]    ${host_index}=${FIRST_CONTROLLER_INDEX}
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${host_index}
    ${connections}    SSHKeywords.Open_Connection_To_ODL_System    ${host}
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Put File    ${READ_SERVICE_SCRIPT}    ${WORKSPACE}/${BUNDLEFOLDER}/    mode=664
    ${module}    OperatingSystem.Get File    ${JSONRPCCONFIG_MODULE_JSON}
    ${data}    OperatingSystem.Get File    ${JSONRPCCONFIG_DATA_JSON}
    ${cmd}    Builtin.Set Variable
    ...    nohup python ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module.replace("\n","").replace(" ","")}' '${data.replace("\n","").replace(" ","")}'
    Log    ${cmd}
    SSHKeywords.Virtual_Env_Set_Path    /tmp/jsonrpc_venv
    SSHKeywords.Virtual_Env_Create_Python3    True
    SSHKeywords.Virtual_Env_Install_Package    pyzmq
    SSHKeywords.Virtual_Env_Install_Package    zmq
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    True
    ${stdout}    SSHLibrary.Write    rm -rf nohup.out
    ${stdout}    SSHLibrary.Write    ${cmd} &
    ${stdout}    SSHLibrary.Write    echo
    Log    ${stdout}
    BuiltIn.Sleep    2s
    ${stdout}    SSHLibrary.Execute Command    /usr/sbin/ss -nlt
    Log    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    cat nohup.out
    Log    ${stdout}
    SSHLibrary.Close_Connection

Mount Read Service Endpoint
    [Documentation]    This keyword mounts an endpoint after starting service
    [Arguments]    ${controller_index}=${FIRST_CONTROLLER_INDEX}    ${file}=${READ_SERVICE_PEER_PAYLOAD}    ${endpoint}=${DEFAULT_ENDPOINT}
    ${JSON1}    OperatingSystem.Get File    ${file}
    Log    ${JSON1}
    ${response_json}    ClusterManagement.Put_As_Json_To_Member
    ...    ${READ_SERVICE_PEER_URL}=${endpoint}
    ...    ${JSON1}
    ...    ${controller_index}
    Builtin.Log    ${response_json}

Verify Data On Mounted Endpoint
    [Documentation]    This keyword verifies if the data we get on the mount point is same as what we put
    [Arguments]    ${controller_index}=${FIRST_CONTROLLER_INDEX}    ${endpoint}=${DEFAULT_ENDPOINT}
    ${resp}    ClusterManagement.Get_From_Member
    ...    ${READ_SERVICE_PEER_URL}=${endpoint}${READ_SERVICE_PEER_MOUNT_PATH}?content=config
    ...    ${controller_index}
    ${response_json}    Builtin.Convert To String    ${resp}
    Log    ${response_json}
    Verify Restconf Get On Mounted Endpoint    ${response_json}    ${READSERVICE_NAME}

Verify Restconf Get On Mounted Endpoint
    [Documentation]    This keyword parses restconf get of mountpoint
    [Arguments]    ${output}    ${name}
    Builtin.Should Match Regexp    ${output}    "name":"${name}"

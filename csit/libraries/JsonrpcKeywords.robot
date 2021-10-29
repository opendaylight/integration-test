*** Settings ***
Library           OperatingSystem
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Resource          ClusterManagement.robot
Resource          ../variables/jsonrpc/JsonrpcVariables.robot
Resource          ../variables/Variables.robot
Resource          SSHKeywords.robot
Resource          Utils.robot

*** Keywords ***
Run Read Service Python Script on Controller Vm
    [Arguments]    ${host_index}=${FIRST_CONTROLLER_INDEX}
    [Documentation]    This keyword creates a new virtual environment, installs pyzmq & zmq and starts the read service on controller vm
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${host_index}
    ${connections}    SSHKeywords.Open_Connection_To_ODL_System    ${host}
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Put File    ${READ_SERVICE_SCRIPT}    ${WORKSPACE}/${BUNDLEFOLDER}/    mode=664
    ${module}    OperatingSystem.Get File    ${JSONRPCCONFIG_MODULE_JSON}
    ${data}    OperatingSystem.Get File    ${JSONRPCCONFIG_DATA_JSON}
    ${cmd}    Builtin.Set Variable    nohup python ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module.replace("\n","").replace(" ","")}' '${data.replace("\n","").replace(" ","")}'
    Log    ${cmd}
    SSHKeywords.Virtual_Env_Set_Path    /tmp/jsonrpc_venv
    SSHKeywords.Virtual_Env_Create    True
    SSHKeywords.Virtual_Env_Install_Package    pyzmq
    SSHKeywords.Virtual_Env_Install_Package    zmq
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    True
    ${stdout}    SSHLibrary.Write    rm -rf nohup.out
    ${stdout}    SSHLibrary.Write    ${cmd} &
    ${stdout}    SSHLibrary.Write    echo
    Log    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    cat nohup.out
    Log    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    /usr/sbin/ss -nltp
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

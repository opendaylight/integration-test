*** Settings ***
Library           OperatingSystem
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Resource          ClusterManagement.robot
Resource          ../variables/jsonrpc/JsonrpcVariables.robot
Resource          ../variables/Variables.robot
Resource          Utils.robot

*** Keywords ***
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
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo python3 -m pip install --upgrade pip    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stdout}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo python3 -m pip install zmq pyzmq    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stdout}
    ${module}    OperatingSystem.Get File    ${JSONRPCCONFIG_MODULE_JSON}
    ${data}    OperatingSystem.Get File    ${JSONRPCCONFIG_DATA_JSON}
    ${cmd}    Builtin.Set Variable    nohup python3 ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}'
    Log    ${cmd}
    ${stdout}    SSHLibrary.Write    echo | rm -rf nohup.out
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    python3 ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}'    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    SSHLibrary.Write    echo | nohup python3 ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}' &
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

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
Run Read Service Python Script
    [Documentation]    This keyword starts the read service on jsonrpc
    ${pip_cmds}    Builtin.Set Variable    sudo yum -y install python-pip; sudo pip install --upgrade pip; sudo pip install zmq pyzmq
    ${rc}    ${Op}    OperatingSystem.Run And Return Rc And Output    ${pip_cmds}
    Log    ${Op}
    Should Be Equal As Integers    ${rc}    0
    ${module}    OperatingSystem.Get File    ${INTERFACES_MODULE_JSON}
    ${data}    OperatingSystem.Get File    ${INTERFACES_DATA_JSON}
    ${cmd}    Builtin.Set Variable    nohup python ${CURDIR}/../variables/jsonrpc/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}' &
    Log    ${cmd}
    ${rc}    ${Op}    OperatingSystem.Run And Return Rc And Output    ${cmd}
    Log    ${Op}
    Should Be Equal As Integers    ${rc}    0

Mount Read Service Endpoint
    [Arguments]    ${controller_index}=${FIRST_CONTROLLER_INDEX}    ${file}=${READ_SERVICE_PEER_PAYLOAD}    ${endpoint}=${DEFAULT_ENDPOINT}    ${target_module}=${DEFAULT_PUT_MODULE}    ${port}=${DEFAULT_PORT}
    [Documentation]    This keyword mounts an endpoint after starting service
    #${ctrl_ip}    ClusterManagement.Resolve IP Address For Member    ${controller_index}
    ${JSON1}    OperatingSystem.Get File    ${file}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Log    ${JSON2}
    ${response_json}    ClusterManagement.Put_As_Json_To_Member    ${READ_SERVICE_PEER_PUT_URL}${endpoint}    ${JSON2}    ${controller_index}
    Builtin.Log    ${response_json}

Verify Data On Mounted Endpoint
    [Arguments]    ${controller_index}=${FIRST_CONTROLLER_INDEX}    ${endpoint}=${DEFAULT_ENDPOINT}
    [Documentation]    This keyword verifies if the data we get on the mount point is same as what we put
    ${resp}    ClusterManagement.Get_From_Member    ${READ_SERVICE_PEER_GET_1}${endpoint}${READ_SERVICE_PEER_GET_2}    ${controller_index}
    Log    ${resp}

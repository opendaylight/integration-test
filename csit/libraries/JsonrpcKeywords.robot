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
Run Read Service Python Script On Robot Vm
    [Arguments]    ${centos_system}=${TRUE}
    [Documentation]    This keyword installs pip,zmq,pyzmq and starts the read service on test vm
    ${cmd}    Builtin.Set Variable If    ${centos_system}    ${CENTOS_PIP}    ${UB_PIP}
    ${rc}    OperatingSystem.Run And Return Rc    ${cmd}
    Log    ${rc}
    ${rc}    OperatingSystem.Run And Return Rc    sudo pip install --upgrade pip
    Log    ${rc}
    ${rc}    OperatingSystem.Run And Return Rc    sudo pip install zmq pyzmq
    Log    ${rc}
    ${module}    OperatingSystem.Get File    ${INTERFACES_MODULE_JSON}
    ${data}    OperatingSystem.Get File    ${INTERFACES_DATA_JSON}
    ${cmd}    Builtin.Set Variable    nohup python ${CURDIR}/../variables/jsonrpc/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '{"ietf-interfaces:interfaces": {}}' '{"interface": [{"name": "test","type": "other"}]}' &
    Log    ${cmd}
    ${rc}    ${Op}    OperatingSystem.Run And Return Rc And Output    ${cmd}
    Log    ${Op}
    Should Be Equal As Integers    ${rc}    0

Return ConnnectionID
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}
    [Documentation]    Returns the connection of any host. Defaults to controller
    ${conn_id}    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Utils.Flexible SSH Login    ${user}    ${password}
    [Return]    ${conn_id}

Run Read Service Python Script on Controller Vm
    [Arguments]    ${host_index}=${FIRST_CONTROLLER_INDEX}    ${centos_system}=${FALSE}
    [Documentation]    This keyword installs pip,zmq,pyzmq and starts the read service on controller vm
    ${cmd}    Builtin.Set Variable If    ${centos_system}    ${UB_PIP}    ${CENTOS_PIP}
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${host_index}
    ${connections}    Return ConnnectionID    ${host}
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
    ${module}    OperatingSystem.Get File    ${INTERFACES_MODULE_JSON}
    ${data}    OperatingSystem.Get File    ${INTERFACES_DATA_JSON}
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    nohup python ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '{"ietf-interfaces:interfaces":{}}' '{"interface":[{"name": "test","type": "other"}]}' &
    ${cmd}    Builtin.Set Variable    nohup python ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}'
    Log    ${cmd}
    ${stdout}    SSHLibrary.Write    echo -ne '\n' | rm -rf nohup.out
    ${stdout}    SSHLibrary.Write    echo -ne '\n' | nohup python ${WORKSPACE}/${BUNDLEFOLDER}/odl-jsonrpc-test-read tcp://0.0.0.0:${DEFAULT_PORT} 'config' ${DEFAULT_ENDPOINT} '${module}' '${data}' &
    ${stdout}    SSHLibrary.Write    echo -ne '\n'
    Log    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    cat nohup.out
    Log    ${stdout}

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
    Log    ${resp}

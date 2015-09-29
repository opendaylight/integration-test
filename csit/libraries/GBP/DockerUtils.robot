*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot

*** Variables ***

*** Keywords ***
Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${count}=1
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ping ${dest_address} -c ${count} >/dev/null 2>&1 && echo success
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Contain    ${output}    success

Start HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}    ${timeout}=20s
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer ${service_port}'
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${stdout}
    Docker Attach    ${docker_name}
    SSHLibrary.Write    python -m SimpleHTTPServer ${service_port} & >/dev/null 2>&1
    SSHLibrary.Write    HTTP_SRV_PID=$!
    Set Client Configuration    timeout=${timeout}
    ${output}    Read Until    port ${service_port}
    Should Contain    ${output}    Serving HTTP

Stop HTTP Service on Docker
    [Arguments]    ${docker_name}
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer'
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${stdout}
    Docker Attach    ${docker_name}
    SSHLibrary.Write    kill $HTTP_SRV_PID

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_addres}    ${service_port}    ${connect_timeout}=2    ${retry}=5
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} curl --connect-timeout ${connect_timeout} --retry ${retry} ${dest_addres}:${service_port} >/dev/null 2>&1 && echo success
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Contain    ${output}    success

*** Keywords ***
Docker Attach
    [Arguments]    ${docker_name}
    SSHLibrary.Write    docker attach ${docker_name}
    SSHLibrary.Write    hostname
    Set Client Configuration    prompt=#
    ${output}    SSHLibrary.Read Until Prompt
    Should Contain    ${output}    ${docker_name}

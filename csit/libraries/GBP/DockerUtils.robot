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

Start Endless Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${count}=1
    SSHLibrary.Write    docker exec ${docker_name} ping ${dest_address} & >/dev/null 2>&1 && echo success
    SSHLibrary.Read Until    success

Start HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}=80    ${timeout}=20s
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer ${service_port}'
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${stdout}
    SSHLibrary.Write    docker exec ${docker_name} python -m SimpleHTTPServer ${service_port} &
    # TODO or maybe try curl 127.0.0.1:port
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer ${service_port}'
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${stdout}

Stop HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}=80
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer ${service_port}' | awk '{print $2}'
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} kill ${stdout}
    ...    return_stdout=True    return_stderr=False    return_rc=False

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_addres}    ${service_port}    ${connect_timeout}=2    ${retry}=5
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ls | grep curl_running
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${output}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} curl --connect-timeout ${connect_timeout} --retry ${retry} ${dest_addres}:${service_port} >/dev/null 2>&1 && echo success
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Contain    ${output}    success

Start Endless Curl from Docker
    [Arguments]    ${docker_name}    ${dest_addres}    ${service_port}    ${connect_timeout}=2    ${retry}=5    ${timeout}=20s    ${sleep}=1
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ls | grep curl_running
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${output}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} touch curl_running && echo success
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Contain    ${output}    success
    SSHLibrary.Write    docker exec ${docker_name} /bin/bash -c "while [ -f curl_running ]; do curl --connect-timeout ${connect_timeout} --retry ${retry} ${dest_addres}:${service_port} && echo success; sleep ${sleep}; done" &
    Set Client Configuration    timeout=${timeout}
    SSHLibrary.Read Until    success

Stop Endless Curl from Docker
    [Arguments]    ${docker_name}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ls | grep curl_running
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${output}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} rm curl_running && echo success
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Contain    ${output}    success

Stop Endless Ping from Docker to Address
    [Arguments]    ${docker_name}    ${dest_address}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'ping ${dest_address}' | grep -v grep | awk '{print $2}'
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${output}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} kill ${output}
    ...    return_stdout=True    return_stderr=False    return_rc=False
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'ping ${dest_address}' | grep -v grep | awk '{print $2}'
    ...    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${output}

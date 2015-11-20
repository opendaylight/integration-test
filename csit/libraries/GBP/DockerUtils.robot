*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot

*** Variables ***

*** Keywords ***
Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${count}=1
    [Documentation]    Sends ICMP requests from docker container to remote address.
    ${output}    ${rc}    SSHLibrary.Execute Command    docker exec ${docker_name} ping ${dest_address} -c ${count} >/dev/null 2>&1 && echo success    return_stdout=True    return_stderr=False    return_rc=True
    Should Contain    ${output}    success
    Should Be Equal As Numbers    ${rc}    0

Start Endless Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}
    [Documentation]    Starts endless ICMP pinging from docker container to remote address.
    Ping from Docker    ${docker_name}    ${dest_address}
    SSHLibrary.Execute Command    docker exec -d ${docker_name} ping ${dest_address}

Start HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}=80    ${timeout}=20s
    [Documentation]    Starts SimpleHTTPServer on docker container. Service port should be idle.
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer ${service_port}'    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${stdout}
    SSHLibrary.Write    docker exec ${docker_name} python -m SimpleHTTPServer ${service_port} &
    Wait Until Keyword Succeeds    2 min    5 sec    Test Port On Docker    ${docker_name}    ${service_port}

Stop HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}=80
    [Documentation]    Stops SimpleHTTPServer on docker container. Service port should not be idle.
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer ${service_port}' | awk '{print $2}'    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} kill ${stdout}    return_stdout=True    return_stderr=False    return_rc=False

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${service_port}=80    ${connect_timeout}=2    ${retry}=3x    ${retry_after}=1s
    [Documentation]    Sends HTTP request to remote server. Endless curl should not be running.
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ls | grep curl_running    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${output}
    Wait Until Keyword Succeeds    ${retry}    ${retry_after}    Execute Curl    ${docker_name}    ${dest_address}    ${service_port}

Start Endless Curl from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${service_port}    ${retry_after}=1s    ${retry}=5    ${timeout}=20s
    ...    ${sleep}=1
    [Documentation]    Starts endless curl from docker container. Only one endless curl can be running on docker container.
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ls | grep curl_running    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${output}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} touch curl_running && echo success    return_stdout=True    return_stderr=False    return_rc=False
    Should Contain    ${output}    success
    Wait Until Keyword Succeeds    ${retry}    ${retry_after}    Execute Curl    ${docker_name}    ${dest_address}    ${service_port}
    ...    endless="TRUE"    sleep=${sleep}

Stop Endless Curl from Docker
    [Arguments]    ${docker_name}
    [Documentation]    Stops endless curl from docker container. Endless curl should be running before stopping it.
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ls | grep curl_running    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${output}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} rm curl_running && echo success    return_stdout=True    return_stderr=False    return_rc=False
    Should Contain    ${output}    success

Stop Endless Ping from Docker to Address
    [Arguments]    ${docker_name}    ${dest_address}
    [Documentation]    Stops endless ping from docker to remote address. Endless ping session should be running before stopping it.
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'ping ${dest_address}' | grep -v grep | awk '{print $2}'    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${output}
    SSHLibrary.Execute Command    docker exec ${docker_name} kill ${output}
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'ping ${dest_address}' | grep -v grep | awk '{print $2}'
    Should Be Empty    ${output}

Test Port On Docker
    [Arguments]    ${docker_name}    ${service_port}
    [Documentation]    Tests if a service is running on service port.
    ${out}    SSHLibrary.Execute Command    docker exec ${docker_name} nc -z -w 5 127.0.0.1 ${service_port} && echo 'opened'
    Should Not Be Empty    ${out}

Execute Curl
    [Arguments]    ${docker_name}    ${dest_address}    ${service_port}    ${endless}="FALSE"    ${sleep}=1
    [Documentation]    Executes curl or curl loop for caller methods based on given parameters.
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} curl ${dest_address}:${service_port} >/dev/null 2>&1 && echo success
    Should Contain    ${output}    success
    Run Keyword If    ${endless} == "TRUE"    SSHLibrary.Execute Command    docker exec -d ${docker_name} /bin/sh -c "while [ -f curl_running ]; do curl ${dest_address}:${service_port} ; sleep ${sleep}; done"
    Log    ${output}

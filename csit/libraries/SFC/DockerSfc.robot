*** Settings ***
Library           SSHLibrary

*** Variables ***

*** Keywords ***
Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${count}=1
    [Documentation]    Sends ICMP requests from docker container to remote address.
    ${output}    ${rc}    SSHLibrary.Execute Command    docker exec ${docker_name} ping ${dest_address} -c ${count} >/dev/null 2>&1 && echo success    return_stdout=True    return_stderr=False    return_rc=True
    Should Contain    ${output}    success
    Should Be Equal As Numbers    ${rc}    0

Stop HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}=80
    [Documentation]    Stops SimpleHTTPServer on docker container. Service port should not be idle.
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} ps aux | grep 'SimpleHTTPServer ${service_port}' | awk '{print $2}'    return_stdout=True    return_stderr=False    return_rc=False
    Should Not Be Empty    ${stdout}
    ${stdout}    SSHLibrary.Execute Command    docker exec ${docker_name} kill ${stdout}    return_stdout=True    return_stderr=False    return_rc=False

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${service_port}=80    ${connect_timeout}=2    ${retry}=5x    ${retry_after}=1s
    [Documentation]    Sends HTTP request to remote server. Endless curl should not be running.
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} ls | grep curl_running    return_stdout=True    return_stderr=False    return_rc=False
    Should Be Empty    ${output}
    Wait Until Keyword Succeeds    ${retry}    ${retry_after}    Execute Curl    ${docker_name}    ${dest_address}    ${service_port}

Test Port On Docker
    [Arguments]    ${docker_name}    ${service_port}
    [Documentation]    Tests if a service is running on service port.
    ${out}    SSHLibrary.Execute Command    docker exec ${docker_name} nc -z -w 5 127.0.0.1 ${service_port} && echo 'opened'
    Should Not Be Empty    ${out}

Execute Curl
    [Arguments]    ${docker_name}    ${dest_address}    ${service_port}    ${endless}="FALSE"    ${sleep}=1
    [Documentation]    Executes curl or curl loop for caller methods based on given parameters.
    Run Keyword If    ${endless} == "TRUE"    Run Keywords    SSHLibrary.Execute Command    docker exec -d ${docker_name} /bin/sh -c "while [ -f curl_running ]; do curl ${dest_address}:${service_port} -m 1 && sleep ${sleep}; done"
    ...    AND    Return From Keyword
    ${output}    SSHLibrary.Execute Command    docker exec ${docker_name} curl ${dest_address}:${service_port} -m 5 >/dev/null 2>&1 && echo success
    Should Contain    ${output}    success

Docker Ovs Start
    [Arguments]    ${nodes}    ${guests}    ${tunnel}    ${odl_ip}    ${log_file}=myFile2.log
    [Documentation]    Run the docker-ovs.sh script with specific input arguments. Run ./docker-ovs.sh --help for more info.
    ${result}    SSHLibrary.Execute Command    ./docker-ovs.sh spawn --nodes=${nodes} --guests=${guests} --tun=${tunnel} --odl=${odl_ip} > >(tee ${log_file}) 2> >(tee ${log_file})    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0

Docker Ovs Clean
    [Arguments]    ${log_file}=myFile3.log
    [Documentation]    Run the docker-ovs.sh script with --clean option to clean up all containers deployment. Run ./docker-ovs.sh --help for more info.
    ${result}    SSHLibrary.Execute Command    ./docker-ovs.sh clean > >(tee ${log_file}) 2> >(tee ${log_file})    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0

Get Docker Ids
    [Documentation]    Execute command docker ps and retrieve the existing containers ids
    ${output}    ${rc}    SSHLibrary.Execute Command    sudo docker ps -q -a    return_stdout=True    return_stderr=False    return_rc=True
    Should Be Equal As Numbers    ${rc}    0
    [Return]    ${output}

Get Docker Ids Formatted
    [Arguments]    ${format}
    [Documentation]    Execute command docker ps with --format argument and retrieve the existing containers names
    ${output}    ${rc}    SSHLibrary.Execute Command    sudo docker ps -a --format ${format}    return_stdout=True    return_stderr=False    return_rc=True
    Should Be Equal As Numbers    ${rc}    0
    [Return]    ${output}

Docker Exec
    [Arguments]    ${docker_name}    ${command}    ${return_contains}=${EMPTY}    ${result_code}=0
    [Documentation]    Execute a command into a docker container.
    ${output}    ${rc}    SSHLibrary.Execute Command    sudo docker exec ${docker_name} ${command}    return_stdout=True    return_stderr=False    return_rc=True
    Run Keyword If    '${return_contains}'!='${EMPTY}'    Should Contain    ${output}    ${return_contains}
    Should Be Equal As Numbers    ${rc}    ${result_code}
    [Return]    ${output}

Multiple Docker Exec
    [Arguments]    ${docker_name_list}    ${command}    ${return_contains}=${EMPTY}    ${result_code}=0
    [Documentation]    Execute a command in a list of dockers and return all the outputs in a list
    @{list_output}=    Create List
    : FOR    ${docker_id}    IN    @{docker_name_list}
    \    ${exec_output}=    Docker Exec    ${docker_id}    ${command}    ${return_contains}    ${result_code}
    \    Append To List    ${list_output}    ${exec_output}
    [Return]    ${list_output}


*** Settings ***
Library           SSHLibrary

*** Variables ***

*** Keywords ***
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

Get Docker Names As List
    [Documentation]    Returns a list with the names of all running containers inside the tools system
    ${docker_ps}=    DockerSfc.Get Docker Ids Formatted    "{{.Names}}" -f status=running
    ${docker_name_list}=    Split String    ${docker_ps}    \n
    [Return]    ${docker_name_list}

Get Docker IP
    [Arguments]    ${docker_name}
    [Documentation]    Obtain the IP address from a given container
    ${output}    ${rc}    SSHLibrary.Execute Command    sudo docker inspect -f '{{.NetworkSettings.IPAddress }}' ${docker_name}    return_stdout=True    return_stderr=False    return_rc=True
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

Get Flows In Docker Containers
    ${docker_list}=    DockerSfc.Get Docker Names As List
    ${docker_flows}    DockerSfc.Multiple Docker Exec    ${docker_list}    ovs-ofctl dump-flows -OOpenflow13 br-int    OFPST_FLOW
    [Return]    ${docker_flows}

Switch Ips In Json Files
    [Arguments]    ${json_dir}    ${container_names}
    ${normalized_dir}=    OperatingSystem.Normalize Path    ${json_dir}/*.json
    : FOR    ${cont_name}    IN    @{container_names}
    \    ${cont_ip}=    Get Docker IP    ${cont_name}
    \    OperatingSystem.Run    sudo sed -i 's/${cont_name}/${cont_ip}/g' ${normalized_dir}

Get Docker Bridge Subnet
    [Documentation]    Obtain the subnet used by docker bridge using the docker inspect tool
    ${output}    ${rc}    SSHLibrary.Execute Command    sudo docker network inspect --format {{.IPAM.Config}} bridge | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/][0-9]{1,2}"    return_stdout=True    return_stderr=False    return_rc=True
    Should Be Equal As Numbers    ${rc}    0
    [Return]    ${output}

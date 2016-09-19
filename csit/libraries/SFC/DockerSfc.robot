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

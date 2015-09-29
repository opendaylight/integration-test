*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot

*** Variables ***

*** Keywords ***
Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}    ${count}=1
    [Documentation]    Attaches to docker and sends a ping. Fails if ping is not successful.
    Docker Attach    ${docker_name}
    SSHLibrary.Write    ping ${dest_address} -c ${count} >/dev/null 2>&1; echo $?
    ${output}=    Read Until Regexp    \\n
    Should Contain    ${output}    0

Start HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}
    Docker Attach    ${docker_name}
    SSHLibrary.Write    python -m SimpleHTTPServer ${service_port} >/dev/null 2>&1 &
    SSHLibrary.Write    HTTP_SRV_PID=$!

Stop HTTP Service on Docker
    [Arguments]    ${docker_name}
    Docker Attach    ${docker_name}
    SSHLibrary.Write    kill $HTTP_SRV_PID

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_addres}    ${service_port}    ${connect_timeout}=2    ${retry}=5
    Docker Attach    ${docker_name}
    SSHLibrary.Write    curl --connect-timeout ${connect_timeout} --retry ${retry} ${dest_addres}:${service_port} >/dev/null 2>&1; echo $?
    ${output}=    Read Until Regexp    \\n
    Should Contain    ${output}    0

Connect to location
    [Arguments]    ${mininet_address}    ${user}    ${password}
    ${mininet_conn_id}=    Open Connection    ${mininet_address}
    Flexible SSH Login     ${user}    ${password}

Docker Attach
    [Arguments]    ${docker_name}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${output}=    Read Until    ${docker_name}

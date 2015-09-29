*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot

*** Variables ***

*** Keywords ***
Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}
    [Documentation]    Attaches to docker and sends a ping. Fails if ping is not successful.
    Docker Attach    ${docker_name}
    SSHLibrary.Write    ping ${dest_address} -c1
    ${output}=    Read Until    statistics
    Log    ${output}
    Should Contain    ${output}    seq=1

Start HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}
    Docker Attach    ${docker_name}
    SSHLibrary.Write    python -m SimpleHTTPServer ${service_port} $
    ${output}=    Read Until Regexp    \\n

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_addres}    ${service_port}
    Docker Attach    ${docker_name}
    SSHLibrary.Write    curl --connect-timeout 2 --retry 5 ${dest_addres}:${service_port}
    # TODO better verification
    ${output}=    Read Until    HTML

Connect to location
    [Arguments]    ${mininet_address}    ${user}    ${password}
    ${mininet_conn_id}=    Open Connection    ${mininet_address}
    Flexible SSH Login     ${user}    ${password}

Docker Attach
    [Arguments]    ${docker_name}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${output}=    Read Until    ${docker_name}


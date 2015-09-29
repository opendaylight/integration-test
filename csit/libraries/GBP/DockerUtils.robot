*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot
 
*** Variables ***

*** Keywords ***
Ping from Docker
    [Arguments]    ${docker_name}    ${dest_address}
    [Documentation]    Attaches to docker and sends a ping. Fails if ping is not successful.
    Docker Attach    ${docker_name}
    ${rc}=    SSHLibrary.Execute Command    ping ${dest_address} -c1    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Start HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}
    Docker Attach    ${docker_name}
    ${rc}=    SSHLibrary.Execute Command    python -m SimpleHTTPServer ${service_port}    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_addres}    ${service_port}
    Docker Attach    ${docker_name}
    ${rc}=    SSHLibrary.Execute Command    curl ${dest_addres}:${service_port}    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0    #this only means that web server returned something (it can be 404)

Connect to location
    [Arguments]    ${mininet_address}    ${user}    ${password}
    ${mininet_conn_id}=    Open Connection    ${mininet_address}
    Flexible SSH Login     ${user}    ${password}

Docker Attach
    [Arguments]    ${docker_name}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${output}=    Read
    Should Contain    ${output}    ${docker_name}
    
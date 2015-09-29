*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
 
*** Variables ***

*** Keywords ***
Ping from Docker
    [Arguments]    ${docker_name}    ${dest_addresses}
    SSHLibrary.Write    sudo docker attach ${docker_name}    
    SSHLibrary.Write    hostname
    ${output}=    Read Until   ${docker_name}
    ${rc}=    Execute Command    ping ${dest_addresses} -c1    return_rc=True
    [Return]    ${rc}
 
Start HTTP Service on Docker
    [Arguments]    ${docker_name}    ${service_port}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${rc}=    Execute Command   python -m SimpleHTTPServer ${service_port}
    [Return]    ${rc}

Curl from Docker
    [Arguments]    ${docker_name}    ${dest_addres}    ${service_port}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${output}=    Read Until   ${docker_name}
    SSHLibrary.Write    curl ${dest_addres}:${service_port}
    ${output}=    Read Until   </html>
    Should Contain    ${output}    </html>

Connect to location
    [Arguments]    ${mininet_address}    ${user}    ${password}
    ${mininet_conn_id}=    Open Connection    ${mininet_address}
    Flexible SSH Login     ${user}    ${password}
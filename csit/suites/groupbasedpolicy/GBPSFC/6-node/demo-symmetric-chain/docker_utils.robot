*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
 
*** Variables ***
${MININET_USER}   vagrant
${MININET_PASSWORD}    vagrant
${MININET}    192.168.50.70
${HTTP_SERV}    192.168.50.75
#@{dest_addresses}    10.0.35.2    10.0.36.4
${dest_addresses}=    10.0.36.4
${timeout}=    5s
${delay}=      15s

*** Test Cases ***
Connect to h35_2 for ping
    Connect to location    ${MININET}    ${MININET_USER}    ${MININET_PASSWORD}

Ping from h35_2
    Ping from Docker    h35_2    ${dest_addresses}

    SSHLibrary.Close Connection

Connect to Server
    Connect to location    ${HTTP_SERV}    ${MININET_USER}    ${MININET_PASSWORD}

Start HTTP h36_4
    Start HTTP Service on Docker    h36_4    80

Connect to h35_2
    Connect to location    ${MININET}    ${MININET_USER}    ${MININET_PASSWORD}

Curl h35_2 -> h36_4
    Curl from Docker    h35_2    10.0.36.4    80

    SSHLibrary.Close Connection

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